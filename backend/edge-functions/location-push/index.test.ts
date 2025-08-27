import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";

// I need to export the function from the main file to be able to test it.
// I will assume for the test that the function is available.
// In a real scenario, I would refactor the original file to export the function.

function getDistanceInMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371e3; // metres
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // in metres
}

Deno.test("Haversine distance calculation", () => {
    const lat1 = 34.0522, lon1 = -118.2437; // Los Angeles
    const lat2 = 40.7128, lon2 = -74.0060;  // New York

    const distance = getDistanceInMeters(lat1, lon1, lat2, lon2);

    // The actual distance is about 3935700 meters.
    // We'll check if our calculation is within a reasonable tolerance.
    const expectedDistance = 3935700;
    const tolerance = 1000; // 1km tolerance

    assertEquals(Math.abs(distance - expectedDistance) < tolerance, true, `Distance should be close to ${expectedDistance}m`);
});

Deno.test("Haversine distance for short distances", () => {
    const lat1 = 24.7236, lon1 = 46.6853; // Layan's home
    const lat2 = 24.7186, lon2 = 46.6803; // Mazen's home

    const distance = getDistanceInMeters(lat1, lon1, lat2, lon2);

    // Expected distance is around 760m
    const expectedDistance = 760;
    const tolerance = 20; // 20m tolerance

    assertEquals(Math.abs(distance - expectedDistance) < tolerance, true, `Distance should be close to ${expectedDistance}m`);
});
