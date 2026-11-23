"""Pruebas sin red ni credenciales: python -m unittest discover -s tools -p test_importar_catalogo_firestore.py"""

import copy
import unittest

import importar_catalogo_firestore as importer


class ImportTests(unittest.TestCase):
    def setUp(self):
        self.products = importer.local_products()
        self.sku = next(iter(self.products))
        self.product = self.products[self.sku]

    def doc(self):
        return {
            "name": f"{importer.DOCUMENTS}/productos/{self.sku}",
            "updateTime": "2026-11-17T00:00:00Z",
            "fields": {k: importer.encode(v) for k, v in self.product.items()},
        }

    def test_local_catalog_has_48_unique_skus_and_real_assets(self):
        self.assertEqual(len(self.products), 48)
        self.assertTrue(all(p["activo"] is True for p in self.products.values()))

    def test_new_documents_require_absence_and_server_timestamps(self):
        plan = importer.plan(self.products, [])
        self.assertEqual(len(plan["nuevos"]), 48)
        self.assertFalse(plan["conflictos"])
        for write in plan["writes"]:
            self.assertEqual(write["currentDocument"], {"exists": False})
            self.assertEqual({t["fieldPath"] for t in write["updateTransforms"]}, {"createdAt", "updatedAt"})
            self.assertNotIn("delete", write)

    def test_existing_business_fields_and_unknown_fields_are_preserved(self):
        doc = self.doc()
        doc["fields"]["precio"] = importer.encode(321)
        doc["fields"]["custom"] = importer.encode("keep")
        doc["fields"].pop("activo")
        before = copy.deepcopy(doc)
        plan = importer.plan({self.sku: self.product}, [doc])
        self.assertEqual(doc, before)
        self.assertFalse(plan["conflictos"])
        self.assertTrue(plan["advertencias_datos_conservados"])
        write = plan["writes"][0]
        self.assertEqual(write["updateMask"]["fieldPaths"], ["activo"])
        self.assertEqual(write["currentDocument"], {"updateTime": doc["updateTime"]})
        self.assertNotIn("precio", write["update"]["fields"])
        self.assertNotIn("custom", write["update"]["fields"])

    def test_correct_existing_document_is_omitted_and_created_at_preserved(self):
        doc = self.doc()
        for key in ("createdAt", "updatedAt"):
            doc["fields"][key] = {"timestampValue": "2026-10-01T00:00:00Z"}
        plan = importer.plan({self.sku: self.product}, [doc])
        self.assertEqual(plan["writes"], [])
        self.assertEqual(plan["omitidos_sin_cambios"], [self.sku])
        doc["fields"]["activo"] = importer.encode(False)
        plan = importer.plan({self.sku: self.product}, [doc])
        self.assertEqual(plan["writes"][0]["updateTransforms"], [{"fieldPath": "updatedAt", "setToServerValue": "REQUEST_TIME"}])

    def test_second_import_of_complete_catalog_is_a_no_op(self):
        docs = []
        for sku, product in self.products.items():
            fields = {k: importer.encode(v) for k, v in product.items()}
            for key in ("createdAt", "updatedAt"):
                fields[key] = {"timestampValue": "2026-11-17T00:00:00Z"}
            docs.append({"name": f"{importer.DOCUMENTS}/productos/{sku}", "updateTime": "2026-11-17T00:00:00Z", "fields": fields})
        plan = importer.plan(self.products, docs)
        self.assertFalse(plan["conflictos"])
        self.assertEqual(plan["writes"], [])
        self.assertEqual(len(plan["omitidos_sin_cambios"]), 48)

    def test_timestamps_only_use_transform_without_replacing_document(self):
        plan = importer.plan({self.sku: self.product}, [self.doc()])
        write = plan["writes"][0]
        self.assertIn("transform", write)
        self.assertNotIn("update", write)

    def test_conflicting_ids_urls_and_bad_schema_are_flagged(self):
        for change in ("sku", "imagenUrl", "precio"):
            doc = self.doc()
            doc["fields"][change] = importer.encode("unexpected")
            plan = importer.plan({self.sku: self.product}, [doc])
            self.assertTrue(plan["conflictos"], change)
        doc = self.doc()
        doc["name"] = f"{importer.DOCUMENTS}/productos/otro-id"
        plan = importer.plan({self.sku: self.product}, [doc])
        self.assertTrue(plan["conflictos"])

    def test_other_documents_are_not_deleted(self):
        doc = self.doc()
        doc["name"] = f"{importer.DOCUMENTS}/productos/EXTRA"
        doc["fields"]["sku"] = importer.encode("EXTRA")
        doc["fields"]["nombre"] = importer.encode("Otro producto")
        doc["fields"]["imagenAsset"] = importer.encode("assets/images/productos/extra.png")
        plan = importer.plan({self.sku: self.product}, [doc])
        self.assertEqual(plan["documentos_ajenos_conservados"], ["EXTRA"])
        self.assertFalse(any("delete" in w for w in plan["writes"]))

    def test_legacy_document_without_sku_is_flagged_as_possible_duplicate(self):
        doc = self.doc()
        doc["name"] = f"{importer.DOCUMENTS}/productos/id-automatico"
        doc["fields"].pop("sku")
        self.assertTrue(importer.plan({self.sku: self.product}, [doc])["conflictos"])

    def test_verify_checks_presence_active_assets_and_timestamps(self):
        doc = self.doc()
        result = importer.verify({self.sku: self.product}, [doc])
        self.assertTrue(result["errores"])
        for key in ("createdAt", "updatedAt"):
            doc["fields"][key] = {"timestampValue": "2026-11-17T00:00:00Z"}
        self.assertEqual(importer.verify({self.sku: self.product}, [doc])["errores"], [])


if __name__ == "__main__":
    unittest.main()
