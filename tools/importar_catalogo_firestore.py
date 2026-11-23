"""Importador conservador. Por defecto solo prepara el reporte; --apply escribe.

python tools/importar_catalogo_firestore.py
python tools/importar_catalogo_firestore.py --apply

Usa la sesion existente de Firebase CLI, sin guardar tokens ni cambiar usuarios.
FIRESTORE_IMPORT_TOKEN permite usar una credencial temporal configurada localmente.
No llama a Authentication, Storage, reglas ni operaciones de borrado.
"""

import argparse
import ast
from collections import Counter
from datetime import datetime, timezone
import json
import math
import os
from pathlib import Path
import re
import sys
import urllib.error
import urllib.parse
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
PROJECT = "andrade-motors-2026"
DATABASE = f"projects/{PROJECT}/databases/(default)"
DOCUMENTS = f"{DATABASE}/documents"
API = "https://firestore.googleapis.com/v1/"
REQUIRED = ("nombre", "categoria", "descripcion", "precio", "stock")


def local_products():
    source = (ROOT / "lib/data/datos_demo.dart").read_text(encoding="utf-8")
    section = source.split("const productos = [", 1)[1].split("\n];", 1)[0]
    blocks = re.findall(r"Producto\((.*?)\n  \),", section, re.S)
    products = {}
    for block in blocks:
        fields = {}
        for key, expression in re.findall(
            r"^    (\w+):\s*(.*?)(?=^    \w+:|\Z)", block, re.M | re.S
        ):
            if key == "icono":
                continue
            expression = expression.strip().removesuffix(",")
            if expression in ("true", "false", "null"):
                fields[key] = {"true": True, "false": False, "null": None}[expression]
            else:
                fields[key] = ast.literal_eval(expression)
        sku = fields.get("sku", "")
        if not re.fullmatch(r"[A-Z0-9][A-Z0-9_-]*", sku) or sku in products:
            raise ValueError(f"SKU invalido o duplicado: {sku}")
        for key in (*REQUIRED[:3], "imagenAsset"):
            if not isinstance(fields.get(key), str) or not fields[key].strip():
                raise ValueError(f"{sku}: campo local invalido {key}")
        if type(fields.get("precio")) not in (int, float) or not math.isfinite(fields["precio"]) or fields["precio"] <= 0:
            raise ValueError(f"{sku}: precio invalido")
        if type(fields.get("stock")) is not int or fields["stock"] < 0:
            raise ValueError(f"{sku}: stock invalido")
        image = (ROOT / fields["imagenAsset"]).resolve()
        if not image.is_relative_to(ROOT / "assets") or not image.is_file():
            raise ValueError(f"{sku}: imagen local inexistente o fuera de assets")
        if fields.get("imagenUrl"):
            raise ValueError(f"{sku}: se exige imagen local, no URL")
        model = (ROOT / "lib/models/producto.dart").read_text(encoding="utf-8")
        for key in ("rating", "resenas"):
            default = re.search(rf"this\.{key}\s*=\s*([\d.]+)", model)
            if key not in fields:
                fields[key] = ast.literal_eval(default.group(1))
        fields["activo"] = True
        products[sku] = fields
    if len(products) != 48:
        raise ValueError(f"Se esperaban 48 SKU; se encontraron {len(products)}")
    return products


def encode(value):
    if value is None:
        return {"nullValue": None}
    if type(value) is bool:
        return {"booleanValue": value}
    if type(value) is int:
        return {"integerValue": str(value)}
    if type(value) is float:
        return {"doubleValue": value}
    if isinstance(value, str):
        return {"stringValue": value}
    if isinstance(value, list):
        return {"arrayValue": {"values": [encode(v) for v in value]}}
    raise ValueError(f"Tipo no admitido: {type(value)}")


def decode(value):
    for key in ("stringValue", "booleanValue", "timestampValue", "nullValue"):
        if key in value:
            return value[key]
    if "integerValue" in value:
        return int(value["integerValue"])
    if "doubleValue" in value:
        return float(value["doubleValue"])
    return None


def timestamp_valid(value):
    try:
        datetime.fromisoformat(value["timestampValue"].replace("Z", "+00:00"))
        return True
    except (KeyError, TypeError, ValueError):
        return False


def plan(products, documents):
    by_id = {d["name"].rsplit("/", 1)[1]: d for d in documents}
    conflicts, warnings, new, updated, omitted, writes = [], [], [], [], [], []
    remote_skus = Counter()
    for doc_id, doc in by_id.items():
        fields = doc.get("fields", {})
        sku = decode(fields.get("sku", {}))
        if isinstance(sku, str):
            normalized = sku.strip().upper()
            remote_skus[normalized] += 1
            if normalized in products and doc_id != normalized:
                conflicts.append(f"{doc_id}: SKU local {normalized} guardado con otro ID")
        for local_sku, local in products.items():
            same_name = str(decode(fields.get("nombre", {})) or "").strip().casefold() == local["nombre"].strip().casefold()
            same_asset = decode(fields.get("imagenAsset", {})) == local["imagenAsset"]
            if doc_id != local_sku and (same_name or same_asset):
                conflicts.append(f"{doc_id}: posible duplicado de {local_sku} por nombre o imagen; requiere revision")
    for sku, count in remote_skus.items():
        if count > 1:
            conflicts.append(f"SKU remoto duplicado: {sku} ({count})")
    for sku, product in products.items():
        name = f"{DOCUMENTS}/productos/{sku}"
        doc = by_id.get(sku)
        if doc is None:
            new.append(sku)
            writes.append({
                "update": {"name": name, "fields": {k: encode(v) for k, v in product.items()}},
                "currentDocument": {"exists": False},
                "updateTransforms": [{"fieldPath": k, "setToServerValue": "REQUEST_TIME"} for k in ("createdAt", "updatedAt")],
            })
            continue
        fields = doc.get("fields", {})
        if "sku" in fields and decode(fields["sku"]) != sku:
            conflicts.append(f"{sku}: campo SKU contradictorio; no se modifica")
        for key in REQUIRED:
            value = decode(fields.get(key, {}))
            valid = (isinstance(value, str) and bool(value.strip())) if key in REQUIRED[:3] else (
                type(value) in (int, float) and math.isfinite(value) and value > 0 if key == "precio" else type(value) is int and value >= 0
            )
            if not valid:
                conflicts.append(f"{sku}: {key} remoto ausente/invalido; requiere revision")
            elif value != product[key]:
                warnings.append(f"{sku}: {key} remoto distinto; se conserva")
        if decode(fields.get("imagenUrl", {})):
            conflicts.append(f"{sku}: imagenUrl existente tiene prioridad en la app; no se elimina sin revision")
        changes = {}
        if decode(fields.get("activo", {})) is not True:
            changes["activo"] = encode(True)
        if decode(fields.get("imagenAsset", {})) != product["imagenAsset"]:
            changes["imagenAsset"] = encode(product["imagenAsset"])
        times = [k for k in ("createdAt", "updatedAt") if not timestamp_valid(fields.get(k, {}))]
        if changes or times:
            if "updatedAt" not in times:
                times.append("updatedAt")
            transforms = [{"fieldPath": k, "setToServerValue": "REQUEST_TIME"} for k in times]
            write = {"currentDocument": {"updateTime": doc["updateTime"]}}
            if changes:
                write.update({"update": {"name": name, "fields": changes}, "updateMask": {"fieldPaths": list(changes)}, "updateTransforms": transforms})
            else:
                write["transform"] = {"document": name, "fieldTransforms": transforms}
            writes.append(write)
            updated.append({"sku": sku, "campos": list(changes) + times})
        else:
            omitted.append(sku)
    return {
        "proyecto": PROJECT, "locales": len(products), "total_remoto_antes": len(documents),
        "nuevos": new, "existentes": [s for s in products if s in by_id],
        "actualizar": updated, "omitidos_sin_cambios": omitted,
        "conflictos": conflicts, "advertencias_datos_conservados": warnings,
        "documentos_ajenos_conservados": [s for s in by_id if s not in products],
        "writes": writes,
    }


def access_token():
    if os.environ.get("FIRESTORE_IMPORT_TOKEN"):
        return os.environ["FIRESTORE_IMPORT_TOKEN"]
    cfg = json.loads((Path.home() / ".config/configstore/firebase-tools.json").read_text(encoding="utf-8"))
    refresh = cfg.get("tokens", {}).get("refresh_token")
    if not refresh:
        raise ValueError("Firebase CLI no tiene una sesion renovable")
    api = Path(os.environ.get("APPDATA", "")) / "npm/node_modules/firebase-tools/lib/api.js"
    source = api.read_text(encoding="utf-8")
    client = re.search(r'const clientId = .*?"FIREBASE_CLIENT_ID", "([^"]+)"', source).group(1)
    secret = re.search(r'const clientSecret = .*?"FIREBASE_CLIENT_SECRET", "([^"]+)"', source).group(1)
    data = urllib.parse.urlencode({"refresh_token": refresh, "client_id": client, "client_secret": secret, "grant_type": "refresh_token"}).encode()
    req = urllib.request.Request("https://www.googleapis.com/oauth2/v3/token", data=data)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)["access_token"]
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"No se pudo renovar la sesion de CLI (HTTP {error.code}); vuelve a autenticar la cuenta autorizada") from None


class Firestore:
    def __init__(self, token):
        self.token = token

    def request(self, method, path, body=None):
        req = urllib.request.Request(API + path, method=method,
            data=json.dumps(body).encode() if body is not None else None,
            headers={"Authorization": "Bearer " + self.token, "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=45) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            message = json.load(error).get("error", {}).get("message", "Acceso rechazado")
            raise RuntimeError(f"Firestore HTTP {error.code}: {message}") from None

    def all_products(self):
        documents, page = [], ""
        while True:
            path = f"{DOCUMENTS}/productos?pageSize=1000" + ("&pageToken=" + urllib.parse.quote(page, safe="") if page else "")
            response = self.request("GET", path)
            documents.extend(response.get("documents", []))
            page = response.get("nextPageToken")
            if not page:
                return documents

    def check_each(self, products, documents):
        response = self.request("POST", DOCUMENTS + ":batchGet", {
            "documents": [f"{DOCUMENTS}/productos/{sku}" for sku in products]})
        found = {r["found"]["name"]: r["found"] for r in response if "found" in r}
        missing = {r["missing"] for r in response if "missing" in r}
        expected = {f"{DOCUMENTS}/productos/{s}" for s in products}
        if set(found) | missing != expected:
            raise RuntimeError("La lectura por SKU quedo incompleta; no se escribe")
        before = {d["name"]: d for d in documents if d["name"] in expected}
        if {n: d["updateTime"] for n, d in found.items()} != {n: d["updateTime"] for n, d in before.items()}:
            raise RuntimeError("El inventario cambio durante la revision; vuelve a generar el plan")


def verify(products, documents):
    by_id = {d["name"].rsplit("/", 1)[1]: d.get("fields", {}) for d in documents}
    errors = []
    for sku, product in products.items():
        f = by_id.get(sku, {})
        if any(k not in f for k in REQUIRED):
            errors.append(sku + ": faltan campos obligatorios")
        if decode(f.get("activo", {})) is not True or decode(f.get("imagenAsset", {})) != product["imagenAsset"]:
            errors.append(sku + ": activo/imagenAsset no coincide")
        if not all(timestamp_valid(f.get(k, {})) for k in ("createdAt", "updatedAt")):
            errors.append(sku + ": timestamps no validos")
    return {"total_firestore": len(documents), "activos_firestore": sum(decode(f.get("activo", {})) is True for f in by_id.values()),
            "locales_presentes": sum(s in by_id for s in products), "errores": errors}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Escribe solo despues de una revision remota completa sin conflictos")
    parser.add_argument("--local-only", action="store_true", help="Valida los 48 productos y sus imagenes sin consultar Firebase")
    args = parser.parse_args()
    products = local_products()
    report_dir = ROOT / "build/firestore-import"
    report_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    report_file = report_dir / f"{stamp}-reporte.json"
    report = {"proyecto": PROJECT, "locales": len(products), "sku_locales": list(products), "estado": "solo_validacion_local"}
    try:
        if args.local_only:
            return
        db = Firestore(access_token())
        documents = db.all_products()
        db.check_each(products, documents)
        report = plan(products, documents)
        report["respaldo_documentos_antes"] = documents
        report["estado"] = "plan_sin_escrituras"
        report_file.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps({k: v for k, v in report.items() if k not in ("writes", "respaldo_documentos_antes")}, ensure_ascii=False, indent=2), flush=True)
        if report["conflictos"]:
            raise RuntimeError("Hay conflictos: no se escribio ningun documento")
        if not args.apply:
            return
        if report["writes"]:
            # Un solo commit atomico. Precondiciones: no sobrescribir documentos nuevos
            # ni cambios concurrentes en documentos existentes. Sin borrados.
            report["estado"] = "commit_enviado_resultado_pendiente"
            report_file.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
            result = db.request("POST", DOCUMENTS + ":commit", {"writes": report["writes"]})
            report["commitTime"] = result.get("commitTime")
        report["estado"] = "commit_confirmado_verificacion_pendiente"
        report_file.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        after = db.all_products()
        report["verificacion"] = verify(products, after)
        after_by_name = {d["name"]: d for d in after}
        for before in documents:
            sku = before["name"].rsplit("/", 1)[1]
            preserved = after_by_name.get(before["name"])
            if preserved is None:
                report["verificacion"]["errores"].append(sku + ": documento previo ausente tras la carga")
                continue
            for key, value in before.get("fields", {}).items():
                if sku in products and key in ("activo", "imagenAsset", "createdAt", "updatedAt"):
                    continue
                if preserved.get("fields", {}).get(key) != value:
                    report["verificacion"]["errores"].append(sku + ": cambio inesperado en " + key)
        report["creados"] = len(report["nuevos"])
        report["actualizados"] = len(report["actualizar"])
        report["estado"] = "completado" if not report["verificacion"]["errores"] else "verificacion_con_errores"
        print(json.dumps(report["verificacion"], ensure_ascii=False, indent=2))
        if report["verificacion"]["errores"]:
            raise RuntimeError("Revisar errores de verificacion; no se realizan borrados ni reintentos automaticos")
    except Exception as error:
        report["error"] = str(error)
        report["estado_previo_al_error"] = report["estado"]
        report["estado"] = "bloqueado_o_incompleto"
        print(str(error), file=sys.stderr)
        raise SystemExit(1) from None
    finally:
        report_file.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print("Reporte:", report_file)


if __name__ == "__main__":
    main()
