// Coordenadas de demostración. Sustituir ambas por las coordenadas verificadas
// de ANDRADE MOTORS y cambiar tiendaDeliveryProvisional a false.
const latitudTiendaDelivery = -12.0651;
const longitudTiendaDelivery = -75.2049;
const tiendaDeliveryProvisional = true;

const tarifasDelivery = [
  (hastaKm: 3.0, costo: 5.0),
  (hastaKm: 6.0, costo: 8.0),
  (hastaKm: 10.0, costo: 12.0),
];

double? cotizarDelivery(double distanciaKm) {
  for (final tramo in tarifasDelivery) {
    if (distanciaKm <= tramo.hastaKm) return tramo.costo;
  }
  return null;
}
