//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//

// DbBulk.prg: Bulk operations on Workareas

/// <summary>
/// </summary>
/// <param name="uSelect"></param>
/// <param name="symField"></param>
/// <returns>
/// </returns>
USING XSharp.RDD.Support


/// <exclude/>
FUNCTION __DBAvg(siValue AS LONG) AS FLOAT
	
	LOCAL  siRet    AS FLOAT
	STATIC siSum    AS FLOAT
	
	IF siValue == 2
		RETURN siSum
	ENDIF
	
	siRet := siSum
	
	IF siValue == 0
		siSum := 0
	ELSE
		siSum := siSum + siValue
	ENDIF
	
	RETURN siRet


/// <exclude />
FUNCTION __UniqueAlias   (cDbfName AS STRING)            AS STRING       
	
	LOCAL cAlias    AS STRING
	LOCAL n         AS DWORD
	LOCAL nSelect   AS DWORD
	
	//  UH 11/09/1999
	//  n := At(".", cDbfName )
	n := RAt(".", cDbfName )
	
	IF n > 0
		cDbfName := SubStr(cDbfName, 1, n - 1)
	ENDIF
	
	n := RAt("\", cDbfName)
	
	IF n > 0
		cDbfName := SubStr(cDbfName, n+1)
	ENDIF
	
	n := 1
	
	cAlias := Upper(cDbfName)
	
	nSelect := @@Select(cAlias)
	
	DO WHILE nSelect > 0
		IF Len(cAlias) < 9
			cAlias := cAlias + AllTrim(Str(n))
		ELSE
			cAlias := SubStr(cAlias, 1, 8) + AllTrim(Str(n))
		ENDIF
		
		n++
		nSelect := @@Select(cAlias)
	ENDDO
	
	RETURN cAlias

/// <exclude />
FUNCTION __DBFLEDIT(aStruct AS ARRAY, aFields AS ARRAY, aList AS ARRAY ) AS ARRAY
    RETURN VoDb.FieldList(aStruct, aFields, aList)

/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbapp/*" />
FUNCTION DbApp(cSourceFile, acFields, cbForCondition, cbWhileCondition,nNext, nRecord, lRest,cDriver, acRDDs, aStruct)     AS LOGIC CLIPPER
	LOCAL siFrom        AS DWORD
	LOCAL siTo          AS DWORD
	LOCAL n, i          AS DWORD
	LOCAL aMatch		AS ARRAY
	LOCAL lRetCode      AS LOGIC
	LOCAL lAnsi         AS LOGIC
	
	lAnsi  := SetAnsi()
    lRetCode := FALSE
    siFrom := 0
	TRY	
		siTo := VoDbGetSelect()
		IF !Used()
			THROW VoDb.DbCmdError(__FUNCTION__)
		ENDIF
		IF aStruct:IsNil
            aStruct := DbStruct()
        ENDIF
        aStruct := VoDb.FieldList(aStruct, acFields, NULL_ARRAY) 
		IF Empty( aStruct)
			THROW VoDb.ParamError(__FUNCTION__, ARRAY, 2)
		ENDIF
		
		DbUseArea(TRUE, cDriver, cSourceFile, __UniqueAlias(cSourceFile), TRUE, TRUE,/*aStru*/,/*cDelim*/, acRDDs)
		siFrom := VoDbGetSelect()
		
		acFields := {}
		
		n := FCount()
		aMatch := DbStruct()
		
		FOR i := 1 TO n
			AAdd(acFields, FieldName(i))
		NEXT
		
		IF ( !lAnsi ) .AND. ( DbInfo(DBI_ISANSI) )
			SetAnsi(.T.)
		ENDIF
		aStruct := VoDb.FieldList(aStruct, acFields, aMatch)
		IF !Empty(aStruct)
			lRetCode := DbTrans(siTo, aStruct, cbForCondition, cbWhileCondition, nNext, nRecord, lRest)
		ENDIF
		
		IF (siFrom > 0)
			VoDbCloseArea()
		ENDIF
		
		VoDbSetSelect(INT(siTo))
		
		
	CATCH e AS Error
		IF  siFrom > 0
			VoDbSetSelect(INT(siFrom))
			VoDbCloseArea()
		ENDIF
		
		e:FuncSym := __FUNCTION__
		THROW Error{e}
    FINALLY
        SetAnsi( lAnsi )
	END TRY
	
	RETURN (lRetCode)


/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbappdelim/*" />
FUNCTION DbAppDelim(cSourceFile, cDelim, acFields, cbForCondition, cbWhileCondition, nNext,nRecord, lRest,aStruct)AS LOGIC CLIPPER
	
	LOCAL siTo          AS DWORD
	LOCAL siPos         AS DWORD
	LOCAL lRetCode      AS LOGIC
	LOCAL lAnsi         AS LOGIC
	LOCAL lDbfAnsi      AS LOGIC
	
	lAnsi  := SetAnsi()
	
	TRY
		
		siTo := VoDbGetSelect()
        IF aStruct:IsNil
            aStruct := DbStruct()
        ENDIF
        aStruct := VoDb.FieldList(aStruct, acFields, NULL_ARRAY) 
		IF Empty( aStruct)
			THROW VoDb.ParamError(__FUNCTION__, ARRAY, 3)
		ENDIF
		
		IF Empty(cSourceFile)
			THROW VoDb.ParamError(__FUNCTION__, STRING, 1)
        ELSE
            siPos := At(".", cSourceFile ) 
			IF siPos == 0
				cSourceFile := cSourceFile + ".TXT"
			ENDIF
		ENDIF
		
		lDbfAnsi := DbInfo(DBI_ISANSI)
		
		DbCreate(cSourceFile, aStruct, "DELIM", .T., __UniqueAlias(cSourceFile), cDelim, .T.)
		
		IF ( !lAnsi .AND. lDbfAnsi)
			SetAnsi(.T.)
		ENDIF
		
		lRetCode := DbTrans(siTo, aStruct, cbForCondition, cbWhileCondition, nNext, nRecord, lRest)
		
		VoDbCloseArea()
		
		VoDbSetSelect(INT(siTo))
		
	CATCH e AS Error
		e:FuncSym := __FUNCTION__
		THROW Error{e}
    FINALLY
        SetAnsi( lAnsi )    
	END TRY
	RETURN (lRetCode)



/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbappsdf/*" />
FUNCTION DbAppSdf(cSourceFile, acFields, cbForCondition,cbWhileCondition, nNext, nRecord, lRest , aStruct  )      AS LOGIC CLIPPER
	
	LOCAL siTo          AS DWORD
	LOCAL siPos         AS DWORD
	LOCAL lRetCode      AS LOGIC
	LOCAL lAnsi         AS LOGIC
	LOCAL lDbfAnsi      AS LOGIC
	
	lAnsi  := SetAnsi()
	
	TRY		
		siTo := VoDbGetSelect()
        IF aStruct:IsNil
            aStruct := DbStruct()
        ENDIF
		aStruct := VoDb.FieldList(aStruct, acFields, NULL_ARRAY) 
		IF (Empty( aStruct ))
			THROW VoDb.ParamError(__FUNCTION__, ARRAY, 2)
		ENDIF
		
		IF Empty(cSourceFile)
			THROW VoDb.ParamError(__FUNCTION__, STRING, 1)
		ELSE
            siPos := At(".", cSourceFile ) 
			IF siPos == 0
				cSourceFile := cSourceFile + ".TXT"
			ENDIF
		ENDIF
		
		lDbfAnsi := DbInfo(DBI_ISANSI)
		
		DbCreate(cSourceFile, aStruct, "SDF", .T., __UniqueAlias(cSourceFile), ,.T.)
		
		IF ( !lAnsi .AND. lDbfAnsi )
			SetAnsi(.T.)
		ENDIF
		
		lRetCode := DbTrans(siTo, aStruct, cbForCondition, cbWhileCondition, nNext, nRecord, lRest)
		
		VoDbCloseArea()
		VoDbSetSelect(INT(siTo))
		
	CATCH e AS Error
		e:FuncSym := __FUNCTION__
		THROW e
    FINALLY
        SetAnsi( lAnsi )    
	END TRY
	RETURN (lRetCode)


/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbcopy/*" />
FUNCTION DbCopy(cTargetFile, acFields, cbForCondition, cbWhileCondition, nNext, nRecord, lRest, cDriver, acRDDs, aStruct    )     AS LOGIC CLIPPER
	
	LOCAL siFrom        AS DWORD
	LOCAL siTo          AS DWORD
	LOCAL lRetCode      AS LOGIC
	LOCAL lAnsi         AS LOGIC
	LOCAL lDbfAnsi      AS LOGIC
	
	lAnsi    := SetAnsi()
	
	siFrom   := VoDbGetSelect()
    siTo    := 0    
	lRetCode := .F.
	
	TRY
		
		IF !Used()
			THROW VoDb.DbCmdError(__FUNCTION__)
		ENDIF
		
		lDbfAnsi := DbInfo(DBI_ISANSI)
		
		IF  Empty(acFields)                      .AND. ;
			cbForCondition:IsNil                      .AND. ;
			cbWhileCondition:IsNil                    .AND. ;
			nNext:IsNil                        .AND. ;
			nRecord:IsNil                         .AND. ;
			Empty(lRest)                        .AND. ;
			cDriver:IsNil                      .AND. ;
			acRDDs:IsNil                      .AND. ;
			( lDbfAnsi == lAnsi )               .AND. ;
			( DbInfo(DBI_MEMOHANDLE) == 0 )     .AND. ;
			(DbOrderInfo(DBOI_ORDERCOUNT) = 0)
			
			lRetCode := DBFileCopy( DbInfo(DBI_FILEHANDLE), cTargetFile, DbInfo(DBI_FULLPATH) )
        ELSE
            IF aStruct:IsNil
                aStruct := DbStruct()
            ENDIF
            aStruct := VoDb.FieldList(aStruct, acFields, NULL_ARRAY)
			IF ( Empty(aStruct) )
				THROW VoDb.ParamError(__FUNCTION__, ARRAY, 2)
			ENDIF
			
			DbCreate( cTargetFile, aStruct, cDriver,, __UniqueAlias(cTargetFile),,,acRDDs)
			
			IF ( !lAnsi ) .AND. ( DbInfo(DBI_ISANSI) )
				SetAnsi(.T.)
			ENDIF
			
			DbUseArea(.T., cDriver, cTargetFile, __UniqueAlias(cTargetFile),,,,,acRDDs)
			
			VoDbSelect(siFrom, REF siTo)
			
			lRetCode := DbTrans(siTo, aStruct, cbForCondition, cbWhileCondition, nNext, nRecord, lRest)
			
			IF (siTo > 0)
				VoDbSetSelect(INT(siTo))
				VoDbCloseArea()
			ENDIF
			
			VoDbSetSelect(INT(siFrom))
		ENDIF
		
    CATCH e AS Error
		SetAnsi(lAnsi)
		e:FuncSym := __FUNCTION__
		THROW e
    FINALLY
        SetAnsi( lAnsi )    
	END TRY
	
	RETURN (lRetCode)


#define BUFF_SIZE 0x00008000
#define FO_CREATE 0x00001000

FUNCTION DBFileCopy( hfFrom AS IntPtr, cFile AS STRING, cFullPath AS STRING) AS LOGIC 
	
	LOCAL lRetCode  AS LOGIC
	LOCAL ptrBuff   AS BYTE[]
	LOCAL hfTo      AS PTR
	LOCAL oError    AS Error
	LOCAL n         AS DWORD
	LOCAL dwPos     AS LONG
	
	
	IF At(".", cFile) == 0
		cFile := cFile + Right(cFullPath, 4)
	ENDIF
	
	hfTo := FCreate( cFile)
	
	IF hfTo == (IntPtr) F_ERROR
		
		oError := Error{1}
		oError:SubSystem                := "DBCMD"
		oError:Gencode                  := EG_OPEN
		oError:OSCode                   := DosError()
		oError:FuncSym                  :=__FUNCTION__
		oError:FileName                 := FPathName()
		
		THROW oError
		
		
	ELSE
		
		dwPos := FSeek3(hfFrom, 0, FS_RELATIVE )
		
		
		FSeek3(hfFrom, 0, FS_SET )
		n       := BUFF_SIZE
		ptrBuff := BYTE[]{n}
		DO WHILE n == BUFF_SIZE
			n := FRead3(hfFrom, ptrBuff, BUFF_SIZE)
			FWrite3(hfTo, ptrBuff, n)
		ENDDO
		
		FClose(hfTo)
		lRetCode := .T.
		FSeek3(hfFrom, dwPos, FS_SET )
	ENDIF
	
	RETURN lRetCode




/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbcopydelim/*" />
FUNCTION DbCopyDelim (cTargetFile, cDelim, acFields, cbForCondition, cbWhileCondition, nNext,nRecord, lRest, aStruct)   AS LOGIC CLIPPER
	
	LOCAL siFrom        AS DWORD
	LOCAL siTo          AS DWORD
	LOCAL siPos         AS DWORD
	LOCAL lRetCode      AS LOGIC
	LOCAL lAnsi         AS LOGIC
	LOCAL lDbfAnsi      AS LOGIC
	lAnsi  := SetAnsi()
	
	siFrom := VoDbGetSelect()
	siTo   := 0
	TRY
		
		IF !Used()
			THROW VoDb.DbCmdError(__FUNCTION__)
		ENDIF
        IF aStruct:IsNil
            aStruct := DbStruct()
        ENDIF
  		aStruct := VoDb.FieldList(aStruct, acFields, NULL_ARRAY)
		IF Empty(aStruct )
			THROW VoDb.ParamError(__FUNCTION__, ARRAY, 3)
		ENDIF
		
		IF Empty(cTargetFile)
			THROW VoDb.ParamError(__FUNCTION__, STRING, 1)
		ELSE
            siPos := At(".", cTargetFile ) 
			IF siPos == 0
				cTargetFile := cTargetFile + ".TXT"
			ENDIF
		ENDIF
		
		lDbfAnsi := DbInfo(DBI_ISANSI)
		
		DbCreate(cTargetFile, aStruct, "DELIM", .T., __UniqueAlias(cTargetFile), cDelim)
		
		IF ( !lAnsi .AND. lDbfAnsi)
			SetAnsi(.T.)
		ENDIF
		
		VoDbSelect(siFrom, REF siTo)
		
		lRetCode := DbTrans(siTo, aStruct, cbForCondition, cbWhileCondition, nNext, nRecord, lRest)
		
		VoDbSetSelect(INT(siTo))
		VoDbCloseArea()
		
	CATCH e AS Error
		e:FuncSym := __FUNCTION__
		THROW e
    FINALLY
        SetAnsi( lAnsi )
		VoDbSetSelect(INT(siFrom))
	END TRY
	
	RETURN (lRetCode)


/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbcopysdf/*" />
FUNCTION DbCopySDF(cTargetFile, acFields, cbForCondition, cbWhileCondition, nNext, nRecord, lRest, aStruct )   AS LOGIC CLIPPER
	
	LOCAL siFrom        AS DWORD
	LOCAL siTo          AS DWORD
	LOCAL siPos         AS DWORD
	LOCAL lRetCode      AS LOGIC
	LOCAL cAlias        AS STRING
	LOCAL lAnsi         AS LOGIC
	LOCAL lDbfAnsi      AS LOGIC
	
	lAnsi  := SetAnsi()
	siFrom := VoDbGetSelect()
    siTo   := 0
	TRY
		
		IF !Used()
			THROW VoDb.DbCmdError(__FUNCTION__)
		ENDIF
        IF aStruct:IsNil
            aStruct := DbStruct()
        ENDIF
		aStruct := VoDb.FieldList(aStruct, acFields, NULL_ARRAY)
		IF Empty(aStruct )
			THROW VoDb.ParamError(__FUNCTION__, ARRAY, 2)
		ENDIF
		
		IF Empty(cTargetFile)
			THROW VoDb.ParamError(__FUNCTION__, STRING, 1)
		ELSE
            siPos := At(".", cTargetFile ) 
			IF siPos == 0
				cTargetFile := cTargetFile + ".TXT"
			ENDIF
		ENDIF
		
		cAlias := __UniqueAlias(cTargetFile)
		
		
		lDbfAnsi := DbInfo(DBI_ISANSI)
		
		DbCreate(cTargetFile, aStruct, "SDF", .T., cAlias)
		
		
		IF ( !lAnsi .AND. lDbfAnsi)
			SetAnsi(.T.)
		ENDIF
		
		VoDbSelect(siFrom, REF siTo)
		
		lRetCode := DbTrans(siTo, aStruct, cbForCondition, cbWhileCondition, nNext, nRecord, lRest)
		
		VoDbSetSelect(INT(siTo))
		VoDbCloseArea()
		
	CATCH e AS Error
		e:FuncSym := __FUNCTION__
		THROW e
    FINALLY
    	SetAnsi( lAnsi )
		VoDbSetSelect(INT(siFrom))
    
	END TRY
	
	
	
	RETURN (lRetCode)



/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbjoin/*" />
FUNCTION DbJoin(cAlias, cTargetFile, acFields, cbForCondition) AS LOGIC CLIPPER
	LOCAL siFrom1       AS DWORD
	LOCAL siFrom2       AS DWORD
	LOCAL siTo          AS DWORD
	LOCAL aStruct       AS ARRAY
	LOCAL lRetCode      AS LOGIC
	
	LOCAL pJoinList     AS _JoinList
	
	IF cbForCondition:IsNil
		cbForCondition := {|| .T.}
	ENDIF
	siTo   := 0
    siFrom1 := 0
	TRY
		
		siFrom1 := VoDbGetSelect()
		
		siFrom2 := @@Select(cAlias)
		
		
		IF siFrom2 = 0
			THROW VoDb.ParamError(__FUNCTION__, STRING, 1)
		ENDIF
		
		VoDbSetSelect(INT(siFrom1))

        aStruct := VoDb.TargetFields(cAlias, acFields, OUT pJoinList)
		IF Empty( aStruct )
			VAR oError := VoDb.DbCmdError(__FUNCTION__)
			oError:SubCode      := EDB_NOFIELDS
			oError:CanDefault    := .F.
			oError:CanRetry      := .F.
			oError:CanSubstitute := .F.
			THROW oError
		ENDIF
		DbCreate( cTargetFile, aStruct,"" , .T., "" )
		VoDbSelect(siFrom1, REF siTo)
		
		pJoinList:uiDestSel := siTo
		
		lRetCode := DbGoTop()
		
		DO WHILE !Eof()
			
			VoDbSetSelect(INT(siFrom2))
			
			lRetCode := DbGoTop()
			
			DO WHILE ! Eof()
				
				VoDbSetSelect(INT(siFrom1))
				
				IF ( Eval(cbForCondition) )
					DbJoinAppend(siTo, pJoinList)
				ENDIF
				
				VoDbSetSelect(INT(siFrom2))
				DbSkip(1)
			ENDDO
			
			VoDbSetSelect(INT(siFrom1))
			
			DbSkip(1)
			
		ENDDO
		
	CATCH e AS Error
		e:FuncSym := __FUNCTION__
		THROW e
    FINALLY
	    IF siTo > 0
		    VoDbSetSelect(INT(siTo))
		    VoDbCloseArea()
	    ENDIF
	
	    VoDbSetSelect(INT(siFrom1))
        
	END TRY
	
	RETURN (lRetCode)

/// <summary>
/// </summary>
/// <returns>
/// </returns>
FUNCTION DbJoinAppend(nSelect AS DWORD, list AS _JoinList)   AS LOGIC        
	RETURN _DbThrowErrorOnFailure(__FUNCTION__, VoDbJoinAppend(nSelect, list))

/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbsort/*" />
FUNCTION DbSort(	cTargetFile, acFields, cbForCondition, cbWhileCondition, nNext, nRecord, lRest )   AS LOGIC CLIPPER
	
	LOCAL siFrom        AS DWORD
	LOCAL siTo          AS DWORD
	LOCAL aStruct       AS ARRAY
	LOCAL lRetCode      AS LOGIC
	LOCAL fnFieldNames  AS _FieldNames
	LOCAL fnSortNames   AS _FieldNames
	LOCAL cRdd 			AS STRING
	
	
	siFrom := VoDbGetSelect()
	siTo   := 0
	DEFAULT(REF lRest, .F.)
	
	TRY
		
		IF !Used()
			THROW VoDb.DbCmdError(__FUNCTION__)
		ENDIF
		
		aStruct := DbStruct()
		
		//	UH 09/23/1997
		cRdd := RddName()
		
		fnFieldNames := VoDb.AllocFieldNames(aStruct)
		
		IF Empty(acFields)
			THROW VoDb.ParamError(__FUNCTION__, ARRAY, 2)
		ENDIF
		
		fnSortNames := VoDb.AllocFieldNames(acFields)
		
		DbCreate(cTargetFile, aStruct, cRdd, .T.)
		VoDbSelect(siFrom, REF siTo)
		lRetCode := VoDbSort(siTo, fnFieldNames, cbForCondition, cbWhileCondition, nNext, nRecord, lRest, fnSortNames)
		
		IF !lRetCode
			THROW Error{RuntimeState.LastRddError}
		ENDIF
		
		IF (siTo > 0)
			VoDbSetSelect(INT(siTo))
			VoDbCloseArea()
		ENDIF
		
		VoDbSetSelect(INT(siFrom))
		
		
	CATCH e AS Error
		e:FuncSym := __FUNCTION__
		THROW e
	END TRY
	
	RETURN lRetCode

/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbtrans/*" />
FUNCTION DbTrans(wTarget, aStruct, cbForCondition, cbWhileCondition, nNext, nRecord, lRest) AS LOGIC CLIPPER
	
	LOCAL fldNames  AS _FieldNames
	
	IF !cbWhileCondition:IsNil
		lRest := .T.
	ENDIF
	
	IF lRest:IsNil
		lRest := .F.
	ENDIF
	
	fldNames := VoDb.AllocFieldNames(aStruct)
	
	RETURN _DbThrowErrorOnFailure(__FUNCTION__, VoDbTrans(wTarget, fldNames, cbForCondition, cbWhileCondition, nNext, nRecord, lRest))



/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbtotal/*" />
FUNCTION DbTotal(cTargetFile, cbKey, acFields,  cbForCondition, cbWhileCondition, nNext, nRecord, lRest, xDriver ) 	AS LOGIC CLIPPER
	
	LOCAL siFrom        AS DWORD
	LOCAL siTo          AS DWORD
	LOCAL i, n          AS DWORD
	LOCAL aStruct       AS ARRAY
	LOCAL aFldNum       AS ARRAY
	LOCAL aNum          AS ARRAY
	LOCAL lSomething    AS LOGIC
	LOCAL kEval         AS USUAL
	LOCAL lRetCode  := FALSE   AS LOGIC
	LOCAL fldNames      AS _FieldNames
	
	IF cbWhileCondition:IsNil
		cbWhileCondition := {|| .T.}
	ELSE
		lRest := .T.
	ENDIF
	
	IF cbForCondition:IsNil
		cbForCondition := {|| .T.}
	ENDIF
	
	IF lRest:IsNil
		lRest := .F.
	ENDIF
	siTo   := 0
	
	IF !nRecord:IsNil
		DbGoto(nRecord)
		nNext := 1
	ELSE
		
		IF nNext:IsNil
			nNext := -1
		ELSE
			lRest := .T.
		ENDIF
		
		IF !lRest
			DbGoTop()
		ENDIF
		
	ENDIF
	
	aFldNum := {}
	
	n := Len(acFields)
	siTo   := 0
	FOR i := 1 TO n
		AAdd(aFldNum, FieldPos( AllTrim(acFields[i]) ) )
	NEXT
	
	aNum  := ArrayNew(n)
	
	TRY
		
		IF !Used()
			THROW VoDb.DbCmdError(__FUNCTION__)
		ENDIF
		
		aStruct := DbStruct()
		
		siFrom := VoDbGetSelect()
		
		aStruct := {}
		
		n := FCount()
		
		FOR i := 1 TO n
			IF DbFieldInfo(DBS_TYPE, i) != "M"
				AAdd(aStruct, { FieldName(i) , DbFieldInfo(DBS_TYPE, i), DbFieldInfo(DBS_LEN, i),  DbFieldInfo(DBS_DEC, i)  })
			ENDIF
		NEXT
		
		IF Empty(aStruct) 
			THROW VoDb.ParamError(__FUNCTION__, ARRAY, 3)
		ENDIF
		
		fldNames := VoDb.AllocFieldNames(aStruct)
		
		//	DbCreate( cTargetFile, aStruct, "", .T.)
		IF xDriver:IsNil
			xDriver := RddSetDefault()
		ENDIF
		DbCreate( cTargetFile, aStruct, xDriver, .T.)
		
		VoDbSelect(siFrom, REF siTo)
		
		n := Len(aFldNum)
		
		DO WHILE ( (!Eof()) .AND. nNext != 0 .AND. Eval(cbWhileCondition) )
			
			lSomething := .F.
			
			AFill(aNum, 0)
			
			kEval := Eval(cbKey)
			
			DO WHILE ( nNext-- != 0 .AND. Eval(cbWhileCondition) .AND. kEval = Eval(cbKey) )
				IF ( Eval(cbForCondition) )
					IF ( !lSomething )
						//	CollectForced()
						lRetCode := VoDbTransRec(siTo, fldNames)
						lSomething := .T.
					ENDIF
					
					FOR i := 1 TO n
						aNum[i] := aNum[i] + FieldGet(aFldNum[i])
					NEXT
					
				ENDIF
				
				DbSkip(1)
				
			ENDDO
			
			IF ( lSomething )
				VoDbSetSelect(INT(siTo))
				
				FOR i := 1 TO n
					FieldPut(aFldNum[i], aNum[i])
				NEXT
				
				VoDbSetSelect(INT(siFrom))
			ENDIF
			
		ENDDO
		
		
		IF (siTo > 0)
			VoDbSetSelect(INT(siTo))
			VoDbCloseArea()
		ENDIF
		
		VoDbSetSelect(INT(siFrom))
		
    CATCH e AS Error
		
		e:FuncSym := __FUNCTION__
		THROW e
	END TRY
	
	
	RETURN (lRetCode)

/// <include file="VoFunctionDocs.xml" path="Runtimefunctions/dbupdate/*" />
FUNCTION DbUpdate(cAlias, cbKey, lRand, cbReplace) AS LOGIC CLIPPER
	
	LOCAL siTo, siFrom  AS DWORD
	LOCAL kEval         AS USUAL
	LOCAL lRetCode      AS LOGIC
	
	siTo := VoDbGetSelect()
	IF (lRand == NIL)
		lRand := .F.
	ENDIF
	
	lRetCode := .T.
	
	TRY
		
		
		IF !Used()
			THROW VoDb.DbCmdError(__FUNCTION__)
		ENDIF
		
		
		DbGoTop()
		
		
		
		
		siFrom := @@Select(cAlias)
		DbGoTop()
		
		DO WHILE !Eof()
			
			kEval := Eval(cbKey)
			
			VoDbSetSelect(INT(siTo))
			
			IF lRand
				
				DbSeek(kEval)
				
				IF Found()
					Eval(cbReplace)
				ENDIF
				
			ELSE
				
				DO WHILE ( Eval(cbKey) < kEval .AND. !Eof() )
					DbSkip(1)
				ENDDO
				
				IF ( Eval(cbKey) == kEval .AND. !Eof() )
					Eval(cbReplace)
				ENDIF
				
			ENDIF
			
			VoDbSetSelect(INT(siFrom))
			
			DbSkip(1)
			
		ENDDO
		
	CATCH e AS Error
		e:FuncSym := __FUNCTION__
		THROW e
    FINALLY
        VoDbSetSelect(INT(siTo))
	END TRY
	
	RETURN (lRetCode)











