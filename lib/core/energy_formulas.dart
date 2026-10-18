/// Rumus bersama untuk estimasi perangkat dan simulasi (PRD bagian 18).
double deviceDailyKwh(double watt, double hours, int quantity) =>
    watt * hours * quantity / 1000;
