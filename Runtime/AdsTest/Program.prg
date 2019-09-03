using XSHarp.ADS
using static XSHarp.ADS
using static System.Console
using VO

FUNCTION MyThrow(e as Exception)
    THROW e

function Start() as void
	local cPath			as string      
	local cSelect		as string
	local oServer		as AdsSqlServer
	local nAdsHandle	as dword
    TRY
    ErrorBlock({|e| MyThrow(e)})
    SetCollation(#Clipper)
	System.Console.OutputEncoding := System.Text.Encoding.UTF8
	cPath			:= "c:\download\test\adssql"
	cSelect			:= "select Datum, Essen from TagMenu order by Datum"

	nADSHandle		:= GetADSHandle( cPath )
	AX_SetConnectionHandle( nADSHandle )
	oServer			:= AdsSqlServer{ cSelect,,, "AXSQLCDX" }
	oServer:GoTop()
	while ! oServer:EoF
		WriteLine( DToC( oServer:FieldGet( "Datum" ) ) + " " + AllTrim( oServer:FieldGet( "Essen" ) ) )
		oServer:Skip()
	end
	oServer:Close()

	WriteLine( "Return to terminate" )	
    ReadLine()
    CATCH e as Exception
        ErrorDialog(e)
    END TRY
	return 

function GetADSHandle( cPath as string ) as IntPtr pascal
	local nRetCode			as dword
	local hConnect			as IntPtr
	local nServerType		as word

	if Upper( Left( cPath, 2 ) ) == "C:" 
		nServerType		:= ACE.ADS_LOCAL_SERVER
	else
		nServerType		:= ACE.ADS_REMOTE_SERVER
	endif
	nRetCode		:= ACE.AdsConnect60( cPath , nServerType, null_psz, null_psz, ACE.ADS_DEFAULT, @hConnect )
	if nRetCode != 0
		hConnect		:= IntPtr.Zero
	endif
	
	return hConnect


CLASS AdsSQLServer INHERIT DBServer
	
CONSTRUCTOR ( oFile, lShareMode, lReadOnlyMode, xDriver, aRdd, @@params ) 
   LOCAL cTemp AS STRING
   LOCAL cFileName AS STRING

   // Set the query text, this is necessary because the VO runtime doesn't like
   // some of the special characters that are used in SQL queries
   RDDINFO( _SET_SQL_QUERY, oFile )

	// Pass the parameter arry into the RDD
	// The params argument should be an array of parameters for the query.
	// The array should be an array of parameter names and parameter values.
	// For example:
	//  {{ "lastname", "Smith" }, { "ID", 25 }}
	IF ( IsNil( params ) )
		// Pass in an empty array.  Passing in NIL doesn't get to the RDD.
		RDDINFO( _SET_SQL_PARAMETERS, {} )
	ELSE
      RDDINFO( _SET_SQL_PARAMETERS, @@params )
	ENDIF
   
   // Some VO libraries have trouble with the alias as is.  So for the SQL RDDS,
   // just grab the first word of the SQL query and use it as the alias.  The VO
   // runtime will adjust it to be unique if there is a naming conflict.
   cTemp := Left( oFile, At( " ", oFile ) - 1 )

   // Call the DBServer init method which will execute the query
   SUPER( cTemp, lShareMode, lReadOnlyMode, xDriver, aRdd )

   // Now that the query is executed, fixup some member variables that couldn't
   // be set properly before the query was executed.  Only do this if the table
   // handle is set (i.e. there is a result set and thus a table in the DBServer)
   IF SELF:Info( DBI_GET_ACE_TABLE_HANDLE ) <> 0
      oFileSpec := FileSpec{ SELF:Info( DBI_FULLPATH ) }
      cFileName := oFileSpec:FileName

      cTemp := Symbol2String( ClassName( SELF ) )
      IF Instr( "2.8", Version())
         oHyperLabel := HyperLabel{ cFileName, cFileName,  ;
            cTemp + ": " + cFileName + " " +  ;
            VO_SPrintF( 5201, Symbol2String( symAlias ) ),  ;
            cTemp + "_" + cFileName }
      ELSEIF Instr( "2.7", Version())
         oHyperLabel := HyperLabel{ cFileName, cFileName,  ;
            cTemp + ": " + cFileName + " " +  ;
            VO_SPrintF( 65201, Symbol2String( symAlias ) ),  ;
            cTemp + "_" + cFileName }
      ELSEIF Instr( "2.6", Version())
         oHyperLabel := HyperLabel{ cFileName, cFileName,  ;
            cTemp + ": " + cFileName + " " +  ;
            VO_SPrintF( 65201, Symbol2String( symAlias ) ),  ;
            cTemp + "_" + cFileName }
      ELSE
         oHyperLabel := HyperLabel{ cFileName, cFileName,  ;
            cTemp + ": " + cFileName + " Alias=" +  ;
            cTemp + "_" + cFileName }
      ENDIF
   ENDIF

RETURN 


METHOD Refresh( @@params ) 
	// This version of Refresh() accepts an array of SQL parameters
	// for the query.  The array should be an array of parameter names and
	// parameter values. For example:
	//  {{ "lastname", "Smith" }, { "ID", 25 }}
	
	// Set the parameters if provided.
	IF params != nil
      RDDINFO( _SET_SQL_PARAMETERS, @@params )
	ENDIF

   return SUPER:Refresh()

END CLASS

