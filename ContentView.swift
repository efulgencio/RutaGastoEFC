import SwiftUI
import MapKit
import SwiftData

// MARK: - CONTENT VIEW PRINCIPAL
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationProvider = LocationProvider()
    
    // --- ESTADOS DE CONFIGURACIÓN ---
    @State private var costePorKm: Double = 0.28
    @State private var mostrarTrafico: Bool = false
    @State private var mostrarMenuOpciones: Bool = false
    @State private var mostrarHistorial: Bool = false
    
    // --- ESTADOS DE MAPA ---
    @State private var puntos: [CLLocationCoordinate2D] = []
    @State private var ruta: MKRoute?
    @State private var posicion: MapCameraPosition = .automatic
    @State private var cargando = false

    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            
            ZStack(alignment: .bottom) {
                vistaMapaPrincipal
                controlesSuperiores(topInset: safeArea.top)
                tarjetaResultado(bottomInset: safeArea.bottom)
            }
        }
        .sheet(isPresented: $mostrarMenuOpciones) { panelAjustes }
        .sheet(isPresented: $mostrarHistorial) {
            HistorialViajesView(alSeleccionar: { viajeSeleccionado in
                self.cargarViajeEnMapa(viajeSeleccionado)
            })
        }
        .onAppear {
            locationProvider.requestPermission()
        }
    }

    // MARK: - COMPONENTES DE INTERFAZ

    private var vistaMapaPrincipal: some View {
        MapReader { proxy in
            Map(position: $posicion) {
                ForEach(Array(puntos.enumerated()), id: \.offset) { index, coord in
                    Marker(index == 0 ? "Origen" : "Destino", coordinate: coord)
                        .tint(index == 0 ? .green : .blue)
                }
                
                if let ruta {
                    MapPolyline(ruta.polyline).stroke(.blue, lineWidth: 6)
                }
            }
            .mapStyle(.standard(emphasis: .automatic, showsTraffic: mostrarTrafico))
            .onMapCameraChange { context in
                posicion = .region(context.region)
            }
            .onTapGesture { screenPoint in
                if let coord = proxy.convert(screenPoint, from: .local) {
                    gestionarToque(coord)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func controlesSuperiores(topInset: CGFloat) -> some View {
        VStack {
            HStack(spacing: 12) {
                Button(action: { mostrarMenuOpciones.toggle() }) {
                    Image(systemName: "gearshape.fill").font(.title3).padding(12).background(.ultraThinMaterial).clipShape(Circle())
                }
                
                Button(action: { mostrarHistorial.toggle() }) {
                    Image(systemName: "clock.arrow.circlepath").font(.title3).padding(12).background(.ultraThinMaterial).clipShape(Circle())
                }
                
                Button(action: usarUbicacionActual) {
                    Image(systemName: "location.fill")
                        .font(.title3).foregroundColor(.white).padding(12).background(Color.blue).clipShape(Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 5)
                }
                
                Spacer()
                
                Button(action: resetTodo) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3.bold()).padding(12).background(Color.red.opacity(0.8)).foregroundColor(.white).clipShape(Circle())
                }
            }
            .padding(.top, topInset > 0 ? topInset : 20).padding(.horizontal, 20)
            Spacer()
        }
    }

    private func tarjetaResultado(bottomInset: CGFloat) -> some View {
        VStack(spacing: 15) {
            HStack {
                Text("Tarifa/Km:").font(.subheadline).bold()
                Spacer()
                HStack(spacing: 15) {
                    Button(action: { if costePorKm > 0.01 { costePorKm -= 0.01 } }) { Image(systemName: "minus.circle.fill").font(.title2) }
                    Text("\(costePorKm, specifier: "%.2f")€").font(.system(.body, design: .monospaced)).bold().frame(width: 60)
                    Button(action: { costePorKm += 0.01 }) { Image(systemName: "plus.circle.fill").font(.title2) }
                }
            }

            if let ruta = ruta {
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        Text("TOTAL").font(.caption).bold().foregroundColor(.secondary)
                        Text("\((ruta.distance/1000) * costePorKm, specifier: "%.2f")€").font(.title2.bold()).foregroundColor(.blue)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if ruta.hasTolls { Label("Peajes", systemImage: "eurosign.circle.fill").font(.caption).foregroundColor(.orange) }
                        Text("\((ruta.distance/1000), specifier: "%.1f") km").font(.subheadline).bold()
                    }
                }
                
                HStack(spacing: 10) {
                    Button(action: guardarViajeConCaptura) {
                        Label(cargando ? "Capturando..." : "Guardar", systemImage: "camera.fill")
                            .font(.subheadline).bold().frame(maxWidth: .infinity).padding().background(.gray.opacity(0.1)).cornerRadius(12)
                    }
                    .disabled(cargando)
                    
                    Button(action: iniciarNavegacionOficial) {
                        Label("Iniciar", systemImage: "arrow.triangle.turn.up.right.circle.fill").font(.subheadline).bold().frame(maxWidth: .infinity).padding().background(.blue).foregroundColor(.white).cornerRadius(12)
                    }
                }
            } else if cargando {
                ProgressView()
            }
        }
        .padding().background(.background).cornerRadius(20).shadow(color: .black.opacity(0.1), radius: 10)
        .padding(.horizontal, 20).padding(.bottom, bottomInset > 0 ? bottomInset + 10 : 30)
    }

    private var panelAjustes: some View {
        NavigationStack {
            List { Toggle("Ver Tráfico Real", isOn: $mostrarTrafico) }
            .navigationTitle("Ajustes").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Hecho") { mostrarMenuOpciones = false } }
        }
        .presentationDetents([.height(180)])
    }

    // MARK: - LÓGICA DE NEGOCIO

    private func gestionarToque(_ coord: CLLocationCoordinate2D) {
        if puntos.count >= 2 { puntos.removeAll(); ruta = nil }
        puntos.append(coord)
        if puntos.count == 2 { obtenerRuta() }
    }

    private func obtenerRuta() {
        cargando = true
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: puntos[0]))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: puntos[1]))
        Task {
            if let response = try? await MKDirections(request: request).calculate(), let route = response.routes.first {
                await MainActor.run {
                    withAnimation {
                        self.ruta = route
                        self.cargando = false
                        self.posicion = .rect(route.polyline.boundingMapRect)
                    }
                }
            } else { await MainActor.run { cargando = false } }
        }
    }

    private func usarUbicacionActual() {
        if let location = locationProvider.lastLocation {
            let coord = location.coordinate
            withAnimation(.easeInOut(duration: 0.8)) {
                posicion = .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)))
            }
            gestionarToque(coord)
        }
    }

    private func cargarViajeEnMapa(_ viaje: Viaje) {
        self.puntos = [CLLocationCoordinate2D(latitude: viaje.latOrigen, longitude: viaje.lonOrigen),
                       CLLocationCoordinate2D(latitude: viaje.latDestino, longitude: viaje.lonDestino)]
        self.costePorKm = viaje.precioPorKm
        obtenerRuta()
    }

    private func iniciarNavegacionOficial() {
        guard puntos.count == 2 else { return }
        let it1 = MKMapItem(placemark: MKPlacemark(coordinate: puntos[0]))
        let it2 = MKMapItem(placemark: MKPlacemark(coordinate: puntos[1]))
        MKMapItem.openMaps(with: [it1, it2], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func guardarViajeConCaptura() {
        guard let r = ruta, puntos.count == 2 else { return }
        cargando = true
        
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(r.polyline.boundingMapRect)
        // Tamaño de la captura
        options.size = CGSize(width: 800, height: 600)
        options.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            let imagenData = snapshot?.image.jpegData(compressionQuality: 0.7)
            
            let nuevoViaje = Viaje(
                nombre: r.name.isEmpty ? "Ruta Calculada" : r.name,
                precioPorKm: costePorKm,
                distanciaMetros: r.distance,
                costeTotal: (r.distance / 1000) * costePorKm,
                latOrigen: puntos[0].latitude,
                lonOrigen: puntos[0].longitude,
                latDestino: puntos[1].latitude,
                lonDestino: puntos[1].longitude,
                fotoMapa: imagenData
            )
            
            modelContext.insert(nuevoViaje)
            cargando = false
            resetTodo()
        }
    }

    private func resetTodo() {
        puntos.removeAll(); ruta = nil
        withAnimation { posicion = .automatic }
    }
}

// MARK: - VISTA DEL HISTORIAL (NUEVO DISEÑO DE TARJETA)
struct HistorialViajesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Viaje.fecha, order: .reverse) var viajes: [Viaje]
    
    var alSeleccionar: (Viaje) -> Void
    
    init(alSeleccionar: @escaping (Viaje) -> Void) {
        self.alSeleccionar = alSeleccionar
    }
    
    var body: some View {
        NavigationStack {
            List {
                if viajes.isEmpty {
                    ContentUnavailableView("Sin rutas", systemImage: "clock", description: Text("Las rutas guardadas aparecerán aquí."))
                } else {
                    ForEach(viajes) { viaje in
                        Button {
                            alSeleccionar(viaje)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                // 1. IMAGEN GRANDE (Aprox 20% de la pantalla)
                                if let data = viaje.fotoMapa, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 180) // Altura destacada
                                        .clipped()
                                        .cornerRadius(12)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.secondary.opacity(0.1))
                                        .frame(height: 180)
                                        .overlay(Image(systemName: "map").font(.largeTitle).foregroundColor(.secondary))
                                }
                                
                                // 2. INFORMACIÓN DEBAJO
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(viaje.nombre)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(viaje.costeTotal, specifier: "%.2f")€")
                                            .font(.title3.bold())
                                            .foregroundColor(.blue)
                                    }
                                    
                                    HStack {
                                        Label("\( (viaje.distanciaMetros/1000), specifier: "%.1f") km", systemImage: "arrow.triangle.pull")
                                        Spacer()
                                        Text(viaje.fecha, style: .date)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 4)
                            }
                        }
                        .listRowSeparator(.hidden) // Opcional: para que parezcan tarjetas separadas
                        .listRowInsets(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                    }
                    .onDelete { offsets in
                        for index in offsets { modelContext.delete(viajes[index]) }
                    }
                }
            }
            .listStyle(.plain) // Estilo de lista más limpio para tarjetas
            .navigationTitle("Historial de Rutas")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
    }
}
