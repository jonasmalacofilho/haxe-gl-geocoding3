package google;

import haxe.Http;
import haxe.Json;
import haxe.Utf8;

//import jonas.Vector;

/*
 * Google Maps Geocoding API V3 Wrapper
 * Based on the wrapper distributed under the MIT License by Jonas Malaco Filho, Copyright (c) 2012
 */

enum ComponentFilter {
	Route( name: String );
	Locality( name: String );
	AdministrativeArea( name: String );
	PostalCode( code: String );
	Country( twoLetterISOCode: String );
}

enum Geocoding3Input {
	Address( ?address: String, ?components: Array<ComponentFilter> );
	LatLon( LatLon: String ); 
}
 
class Geocoding3 {
	
	public var input( default, null ) : Geocoding3Input;
	public var response( default, null ) : Dynamic;
	public var responseStatusOk( default, null ) : Bool;

	static inline var apiUrl = 'http://maps.googleapis.com/maps/api/geocode/json';
	static inline var sensor = 'false';
	
	public static inline var defaultLanguage = 'en';
	
	public function new( input : Geocoding3Input ) {
		this.input = input;
	}
	
	public function request( ?region : String, ?language : String ) : List<Geocoding3Result> {
		response = null;
		responseStatusOk = false;
		var cnx = new Http( apiUrl );
		cnx.onData = function( data ) { response = Json.parse( data ); };
		cnx.onError = function( msg ) { throw 'http request raised $msg'; };
		switch ( input ) {
			case Address( address, components ):
				if ( address != null )
					setParameter( cnx, 'address', address );
				if ( components != null && components.length > 0 ) {
					var cfp = [];
					for ( cf in components )
						switch ( cf ) {
							case Route( name ): cfp.push( 'route:' + name );
							case Locality( name ): cfp.push( 'locality:' + name );
							case AdministrativeArea( name ): cfp.push( 'administrative_area:' + name );
							case PostalCode( code ): cfp.push( 'postal_code:' + code );
							case Country( code ): cfp.push( 'country:' + code );
						}
					setParameter( cnx, 'components', cfp.join( '|' ) );
				}
			case LatLon( latLon ):
				cnx.setParameter( 'latlng', latLon );
			default:
				throw  'bad input $input';
		}
		if ( null != region )
			cnx.setParameter( 'region', region );
		if ( null != language )
			cnx.setParameter( 'language', language );
		cnx.setParameter( 'sensor', sensor );
		cnx.request( false );
		if ( null != response ) {
			responseStatusOk = response.status == 'OK';
			if ( !responseStatusOk ) {
				throw 'Geocoding API return status = ${response.status}' ;
			}
		}
		var x = new List();
		if ( null != response && response.status == 'OK' ) {
			for ( r in cast( response.results, Array<Dynamic> ) ) {
				x.add( new Geocoding3Result( r.geometry.location.lat, r.geometry.location.lng, r.formatted_address, r.geometry.location_type ) );
			}
		}
		return x;
	}
	
	public static function setParameter( cnx: Http, param: String, value: String ) {
		if ( !Utf8.validate( param ) )
			param = Utf8.encode( param );
		if ( !Utf8.validate( value ) )
			value = Utf8.encode( value );
		cnx.setParameter( param, value );
	}

}

class Geocoding3Result {
	public var lat : Float;
	public var lon : Float;
	public var formattedAddress : String;
	public var geometryLocationType : String;
	public function new( lat : Float, lon : Float, formattedAddress, geometryLocationType : String ) {
		this.lat = lat;
		this.lon = lon;
		this.formattedAddress = formattedAddress;
		this.geometryLocationType = geometryLocationType;
	}
}
