//
//  ViewController.swift
//  buscadorMapas
//
//  Created by Ramiro y Jennifer on 28/04/21.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var buscadorSB: UISearchBar!
    @IBOutlet weak var MapaMK: MKMapView!
    
    var latitud: CLLocationDegrees?
    var longitud: CLLocationDegrees?
    var altitud: Double?
    
    
    //manager para hacer uso del GPS
    var manager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buscadorSB.delegate = self
        MapaMK.delegate = self
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
        
        //mejorar la presiocion de la ubicacióniu
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        //Monitorear en todo momento la ubicacion
        manager.startUpdatingLocation()
        
    }

    @IBAction func UbicacionButton(_ sender: UIBarButtonItem) {
        
        let alerta = UIAlertController(title: "Ubicacion", message: "Las coordenadas son: \(latitud  ?? 0) \(longitud ?? 0) \(altitud ?? 0)", preferredStyle: .alert)
        
        let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        
        alerta.addAction(accionAceptar)
        present(alerta, animated: true)
        
        let localizacion = CLLocationCoordinate2DMake(latitud!, longitud!)
        
        let spanMapa = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        let region = MKCoordinateRegion(center: localizacion, span: spanMapa)
        
        MapaMK.setRegion(region, animated: true)
        MapaMK.showsUserLocation  = true
        
    }
    
}

extension ViewController: CLLocationManagerDelegate, UISearchBarDelegate, MKMapViewDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        print("Numero de ubicaciones \(locations.count)")
        
        guard let ubicacion = locations.first else {
            return
        }
        latitud = ubicacion.coordinate.latitude
        longitud = ubicacion.coordinate.longitude
        altitud = ubicacion.altitude
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener ubicacion \(error.localizedDescription)")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //print("Ubicacion encontrada!")
        //metodo para ocultar el teclado
        buscadorSB.resignFirstResponder()
        let geocoder = CLGeocoder()
        if let direccion = buscadorSB.text {
            geocoder.geocodeAddressString(direccion) { (places: [CLPlacemark]?, error: Error?) in
                
                //crear el destino
                guard let destinoRuta = places?.first?.location else {
                    return
                }
                
                if error == nil{
                    //Buscar la direccion en el mapa
                    let lugar = places?.first
                    let anotacion = MKPointAnnotation()
                    anotacion.coordinate = (lugar?.location?.coordinate)!
                    anotacion.title = direccion
                    
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    let region = MKCoordinateRegion(center: anotacion.coordinate, span: span)
                    
                    self.MapaMK.setRegion(region, animated: true)
                    self.MapaMK.addAnnotation(anotacion)
                    self.MapaMK.selectAnnotation(anotacion, animated: true)
                    
                    //mandar llamar a trazar ruta
                    self.trazarRuta(coordenadasDestino: destinoRuta.coordinate)
                    
                    let origen = CLLocation(latitude: self.latitud ?? 0, longitude: self.longitud ?? 0)
                    
                    let distancia = origen.distance(from: destinoRuta)
                    print("Distancia obtenida \(distancia)")
                    let distanciaKM = String(format: "%.2f", distancia/1000)
                    print("Distancia en KM \(distanciaKM) KM")
                    
                    
                    let alerta = UIAlertController(title: "Distancia", message: "La distancia entre tu ubicación y el destino es \(distanciaKM)", preferredStyle: .alert)
                    
                    let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
                    
                    alerta.addAction(accionAceptar)
                    self.present(alerta, animated: true)
                    
                }else{
                    print("Error al encontrar la direccion \(error?.localizedDescription)")
                }
            }
        }
    }
    
    //MARK: trazar la ruta
    func trazarRuta(coordenadasDestino: CLLocationCoordinate2D){
        guard let coordOrigen = manager.location?.coordinate else {
            return
        }
        //crear un lugar de origen-destino
        let origenPlaceMark = MKPlacemark(coordinate: coordOrigen)
        let destinoPlaceMark = MKPlacemark(coordinate: coordenadasDestino)
        
        //Crear un objeto en mapkit Item
        let origenItem = MKMapItem(placemark: origenPlaceMark)
        let destinoItem = MKMapItem(placemark: destinoPlaceMark)
        
        //Solicitud de ruta
        let solicitudDestino = MKDirections.Request()
        solicitudDestino.source = origenItem
        solicitudDestino.destination = destinoItem
        //como se va a viajar
        solicitudDestino.transportType = .automobile
        solicitudDestino.requestsAlternateRoutes = true
        
        let direcciones = MKDirections(request: solicitudDestino)
        direcciones.calculate { (respuesta, error) in
            //variable segura
            guard let respuestaSegura = respuesta else{
                if let error = error{
                    print("Error al calcular la ruta \(error.localizedDescription)")
                }
                return
            }
            
            //si todo salio bien
            print(respuestaSegura.routes.count)
            let ruta = respuestaSegura.routes[0]
            //Agregar al mapa una superposicion
            self.MapaMK.addOverlay(ruta.polyline)
            self.MapaMK.setVisibleMapRect(ruta.polyline.boundingMapRect, animated: true)
        }
    }
    
    //MARK: superposicion
    //metodo para agregar la superposicion al mapa
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderizado = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderizado.strokeColor = .purple
        return renderizado
    }
    
    
}
