import Foundation
import SwiftData

@Model
class Viaje {
    // Información básica del viaje
    var nombre: String
    var fecha: Date
    var precioPorKm: Double
    var distanciaMetros: Double
    var costeTotal: Double
    
    // Coordenadas de origen
    var latOrigen: Double
    var lonOrigen: Double
    
    // Coordenadas de destino
    var latDestino: Double
    var lonDestino: Double
    
    // Captura del mapa (guardada fuera de la base de datos principal para optimizar)
    @Attribute(.externalStorage) var fotoMapa: Data?
    
    init(
        nombre: String,
        precioPorKm: Double,
        distanciaMetros: Double,
        costeTotal: Double,
        latOrigen: Double,
        lonOrigen: Double,
        latDestino: Double,
        lonDestino: Double,
        fotoMapa: Data? = nil
    ) {
        self.nombre = nombre
        self.fecha = Date() // Se asigna la fecha actual automáticamente al crear el viaje
        self.precioPorKm = precioPorKm
        self.distanciaMetros = distanciaMetros
        self.costeTotal = costeTotal
        self.latOrigen = latOrigen
        self.lonOrigen = lonOrigen
        self.latDestino = latDestino
        self.lonDestino = lonDestino
        self.fotoMapa = fotoMapa
    }
}
