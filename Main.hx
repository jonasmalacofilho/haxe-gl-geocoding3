import haxe.Json;
import google.Geocoding3;

class Main {
	
	static function main() {
		var opt = new Hash<Dynamic>();
		var optPush = function ( key, value: Dynamic ) {
			if ( opt.exists( key ) )
				opt.get( key ).push( value );
			else
				opt.set( key, [ value ] );
		};
		var args = Lambda.list( Sys.args() );
		try {
			while ( !args.isEmpty() ) {
				var a = args.pop();
				switch ( a ) {
					case '--reverse', '-r' : opt.set( '--reverse', true );
					case '--sql' : opt.set( '--sql', { table : args.pop(), label : args.pop() } ); 
					case '--region': opt.set( '--region', args.pop() );
					case '--language': opt.set( '--language', args.pop() );
					case '--filter-route': optPush( 'components', Route( args.pop() ) );
					case '--filter-locality': optPush( 'components', Locality( args.pop() ) );
					case '--filter-administrative-area': optPush( 'components', AdministrativeArea( args.pop() ) );
					case '--filter-postal-code': optPush( 'components', PostalCode( args.pop() ) );
					case '--filter-country': optPush( 'components', Country( args.pop() ) );
					default : opt.set( '_input', a );
				}
			}
			if ( !opt.exists( '--reverse' ) && !opt.exists( 'components' ) && ( !opt.exists( '_input' ) || StringTools.trim( opt.get( '_input' ) ).length == 0 ) )
				throw 'bad input';
		}
		catch ( e : String ) {
			if ( e == 'bad input' ) {
				Sys.println( 'gl-geocode.exe [options] query' );
				Sys.println( '\nOptions:' );
				Sys.println( '\t--reverse, -r: perform a reverse geocoding' );
				Sys.println( '\t--filter-postal-code <postal code>: use postal code in query' );
				Sys.println( '\t--sql <table name> <label>: output sql insert statements' );
				Sys.exit( 1 );
			}
			else neko.Lib.rethrow( e );
		}
		var obj;
		if ( opt.get( '--reverse' ) == true )
			obj = new Geocoding3( LatLon( opt.get( '_input' ) ) );
		else
			obj = new Geocoding3( Address( opt.get( '_input' ), opt.get( 'components' ) ) );
		if ( opt.exists( '--sql' ) ) {
			var sql = opt.get( '--sql' );
			Sys.println( Std.format( 'CREATE TABLE IF NOT EXISTS \"${sql.table}\" ( label TEXT, formattedAddress TEXT, lat REAL, lon REAL, geometryLocationType TEXT, PRIMARY KEY ( label ) );' ) );
			for ( r in obj.request( opt.get( '--region' ), opt.get( '--language' ) ) )
				Sys.println( Std.format( 'INSERT OR REPLACE INTO \"${sql.table}\" ( label, formattedAddress, lat, lon, geometryLocationType ) VALUES ( \'${sql.label}\', \'${r.formattedAddress}\', ${r.lat}, ${r.lon}, \'${r.geometryLocationType}\' );' ) );
		}
		else {
			for ( r in obj.request( opt.get( '--region' ), opt.get( '--language' ) ) )
				Sys.println( Json.stringify( r ) );
		}
	}
	
}
