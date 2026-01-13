RutaGastoEFC 🚗💨
RutaGastoEFC es una aplicación nativa para iOS diseñada para ayudar a conductores y empresas a calcular el coste real de sus trayectos. Utilizando la potencia de MapKit y SwiftData, la app permite visualizar rutas, ajustar tarifas por kilómetro y mantener un historial visual de los gastos de viaje.

✨ Características
Cálculo en Tiempo Real: Determina el coste de una ruta basándose en una tarifa por kilómetro ajustable (0.01€ - 1.00€+).

Interfaz de Mapas Avanzada:

Selección de puntos de origen y destino mediante toques en el mapa.

Botón de Ubicación Actual con zoom inteligente para marcar el punto de partida rápidamente.

Visualización de tráfico real y avisos de peajes/obras.

Persistencia con SwiftData:

Guardado local de rutas incluyendo nombre, fecha, distancia y coste.

Capturas de Pantalla Automáticas: Cada viaje guardado genera una miniatura visual de la ruta usando MKMapSnapshotter.

Historial Visual: Listado de viajes en formato "tarjeta" con imágenes grandes y detalles claros.

Navegación GPS: Acceso directo a Apple Maps para iniciar la navegación guiada por voz con un solo toque.

🛠️ Tecnologías Utilizadas
SwiftUI: Para una interfaz moderna y reactiva.

MapKit: Motor de mapas, geocodificación y cálculo de rutas de Apple.

SwiftData: Gestión de base de datos local (sucesor de Core Data).

CoreLocation: Gestión de permisos y posicionamiento GPS.

Asignación Asíncrona (Swift Concurrency): Para cálculos de ruta y capturas de mapa sin bloquear la interfaz.

🚀 Instalación y Requisitos
Xcode: Versión 15.0 o superior.

iOS: Versión 17.0 o superior (necesaria para SwiftData).

Configuración de Permisos:

Es necesario añadir la clave Privacy - Location When In Use Usage Description en el archivo Info.plist para que el GPS funcione correctamente.

Bash

# Instalación.
Crea tu proyecto y añade las clases. Añade los permisos necesarios.

🛤️ Próximas Mejoras (Roadmap)
[ ] Opción para Evitar Peajes y Autopistas en los ajustes.

[ ] Perfiles de Vehículos (Coche, Moto, Furgoneta) con tarifas predefinidas.

[ ] Exportación de historial a PDF o CSV.

[ ] Soporte para Modo Oscuro optimizado.
