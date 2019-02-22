//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//

USING XSharp.RDD.Support
USING XSharp.RDD.CDX
USING System.IO
BEGIN NAMESPACE XSharp.RDD
    // Inherits all standard DBF and Memo behavior
    // Only adds Order Handling
    /// <summary>DBFCDX RDD. For DBF/FPT/CDX.</summary>
    CLASS DBFCDX INHERIT DBFFPT
        INTERNAL _indexList  AS CdxOrderBagList
        INTERNAL PROPERTY CurrentOrder AS CdxTag GET _indexList:CurrentOrder
        
            CONSTRUCTOR()
                SUPER()
                _indexList := CdxOrderBagList{SELF}
                RETURN
                
            PROPERTY SysName AS STRING GET typeof(DBFCDX):ToString()
            #REGION Order Support
            
            VIRTUAL METHOD OrderCreate(orderInfo AS DbOrderCreateInfo ) AS LOGIC
                RETURN SELF:_indexList:Create(orderInfo)
                
            VIRTUAL METHOD OrderDestroy(orderInfo AS DbOrderInfo ) AS LOGIC
                RETURN SUPER:OrderDestroy(orderInfo)
                
            VIRTUAL METHOD OrderListAdd( orderInfo AS DbOrderInfo) AS LOGIC
                BEGIN LOCK SELF
                    SELF:GoCold()
                    LOCAL fullPath AS STRING
                    fullPath := orderInfo:BagName
                    IF File(fullPath)
                        fullPath := FPathName()
                    ELSEIF ! String.IsNullOrEmpty(Path.GetExtension(fullPath)) 
                        fullPath := Path.ChangeExtension(fullPath, CdxOrderbag.CDX_EXTENSION)
                        IF File(fullPath)
                            fullPath := FPathName()
                        ENDIF
                    ENDIF
                    IF String.IsNullOrEmpty(System.IO.Path.GetDirectoryName(fullPath))
                        fullPath := System.IO.Path.Combine(SYstem.IO.Path.GetDirectoryName(SELF:_FileName), fullPath)
                        orderinfo:BagName := fullPath
                    ENDIF
                    LOCAL lOk := FALSE AS LOGIC
                    IF SELF:_indexList:FindOrderBag(orderInfo:BagName) == NULL
                        lOk := SELF:_indexList:Add(orderInfo)
                        IF lOk .AND. SELF:_indexList:Count == 1
                            // After opening the first index file the first order in the file becomes active
                            orderInfo := DbOrderInfo{}
                            orderInfo:Order := 1
                            lOk := SELF:OrderListFocus(orderInfo)
                        ENDIF
                    ELSE
                        // Already open, do nothing
                        lOk := TRUE
                    ENDIF
                    RETURN lOk
                END LOCK
                
            VIRTUAL METHOD OrderListDelete(orderInfo AS DbOrderInfo) AS LOGIC
            
                BEGIN LOCK SELF
                    SELF:GoCold()
                    RETURN SELF:_indexList:CloseAll()
                END LOCK            
                
            VIRTUAL METHOD OrderListFocus(orderInfo AS DbOrderInfo) AS LOGIC
            
                BEGIN LOCK SELF
                    SELF:GoCold()
                    RETURN SELF:_indexList:SetFocus(orderInfo)
                END LOCK
                
            VIRTUAL METHOD OrderListRebuild() AS LOGIC
                BEGIN LOCK SELF
                    SELF:GoCold()
                    RETURN SELF:_indexList:Rebuild()
                END LOCK
                
                
            OVERRIDE METHOD OrderInfo(nOrdinal AS DWORD , info AS DbOrderInfo ) AS OBJECT
                LOCAL result AS LONG
                LOCAL workOrder AS CdxTag
                LOCAL isOk := FALSE AS LOGIC
                
                result := 0
                workOrder := SELF:_indexList:FindOrder(info)
                IF workOrder == NULL
                    workOrder := SELF:CurrentOrder
                ENDIF
                
                BEGIN SWITCH nOrdinal
            CASE DBOI_CONDITION
                IF workOrder != NULL
                    info:Result := workOrder:Condition
                ENDIF
            CASE DBOI_EXPRESSION
                IF workOrder != NULL
			        info:Result := workOrder:Expression
        	    ENDIF
            CASE DBOI_ORDERCOUNT
                info:Result := SELF:_indexList:Count
            CASE DBOI_POSITION
                IF workOrder == NULL
                    info:Result := SELF:RecNo
                ELSE
                    isOk := workOrder:_getRecPos( REF result)
                    IF isOk
                        info:Result := result
                    ENDIF
                ENDIF
            CASE DBOI_KEYCOUNT
                result := 0
                IF workOrder != NULL
                    info:Result := 0
                    isOk := workOrder:_CountRecords(REF result)
                ENDIF
                IF isOk
                    info:Result := result
                ENDIF
            CASE DBOI_NUMBER
                info:Result := SELF:_indexList:OrderPos(workOrder)
            CASE DBOI_BAGEXT
                // according to the docs this should always return the default extension and not the actual extension
                info:Result := CdxOrderBag.CDX_EXTENSION
            CASE DBOI_FULLPATH
                IF workOrder != NULL
                    info:Result := workOrder:OrderBag:FullPath
                ELSE
                    info:Result := ""
                ENDIF
            CASE DBOI_BAGNAME
                IF workOrder != NULL
                    info:Result := workOrder:FileName
                ELSE
                    info:Result := ""
                ENDIF
            CASE DBOI_NAME
                IF workOrder != NULL
                    info:Result := workOrder:_orderName
                ELSE
                    info:Result := ""
                ENDIF
            CASE DBOI_FILEHANDLE
                IF workOrder != NULL
                    info:Result := workOrder:OrderBag:Handle
                ELSE
                    info:Result := IntPtr.Zero
                ENDIF
            CASE DBOI_ISDESC
                IF workOrder != NULL
                    info:Result := workOrder:_Descending
                ELSE
                    info:Result := FALSE
                ENDIF
            CASE DBOI_ISCOND
                IF workOrder != NULL
				    info:Result := workOrder:_Conditional
                ELSE
                    info:Result := FALSE
                ENDIF
            CASE DBOI_KEYTYPE
                IF workOrder != NULL
                    info:Result := workOrder:_KeyExprType
                ELSE
                    info:Result := 0
                ENDIF
            CASE DBOI_KEYSIZE
                IF workOrder != NULL
                    info:Result := workOrder:_keySize
                ELSE
                    info:Result := 0
                ENDIF
            CASE DBOI_KEYDEC
			    info:Result := 0
            CASE DBOI_UNIQUE
                IF workOrder != NULL
                    info:Result := workOrder:Unique
                ELSE
                    info:Result := FALSE
                ENDIF
            CASE DBOI_LOCKOFFSET
                IF workOrder != NULL
                    info:Result := workOrder:OrderBag:_lockOffset
                ELSE
                    info:Result := 0
                ENDIF
            CASE DBOI_SETCODEBLOCK
                IF workOrder != NULL
					info:Result := workOrder:_KeyCodeBlock
				ENDIF
            CASE DBOI_KEYVAL
                IF workOrder != NULL
                    isOk := TRUE
                    TRY
					info:Result := SELF:EvalBlock(workOrder:_KeyCodeBlock)
                    CATCH
                        isOk := FALSE
                    END TRY
                    IF !isOk
                        info:Result := NULL
                    ENDIF
                ELSE
                    info:Result := NULL
                ENDIF
            CASE DBOI_SCOPETOP
                IF workOrder != NULL
                    IF info:Result != NULL
                        workOrder:SetOrderScope(info:Result, XSharp.RDD.Enums.DbOrder_Info.DBOI_SCOPETOP)
                    ENDIF
                    info:Result := workOrder:_topScope
                ELSE
                    info:Result := NULL
                ENDIF
            CASE DBOI_SCOPEBOTTOM
                IF workOrder != NULL
                    IF info:Result != NULL
                        workOrder:SetOrderScope(info:Result, XSharp.RDD.Enums.DbOrder_Info.DBOI_SCOPEBOTTOM)
                    ENDIF
                    info:Result := workOrder:_bottomScope
                ELSE
                    info:Result := NULL
                ENDIF
            CASE DBOI_SCOPETOPCLEAR
                IF workOrder != NULL
                    workOrder:_hasTopScope := FALSE
                    workOrder:_topScope := NULL
                ENDIF
            CASE DBOI_SCOPEBOTTOMCLEAR
                IF workOrder != NULL
                    workOrder:_hasBottomScope := FALSE
                    workOrder:_bottomScope := NULL
                ENDIF
            CASE DBOI_USER + 42
                // Dump Cdx to Txt file
                IF workOrder != NULL
                    workOrder:_dump()
                ENDIF
                    
            OTHERWISE
                SUPER:OrderInfo(nOrdinal, info)
            END SWITCH
            RETURN info:Result
            
            #endregion

        #region Pack, Zap
        METHOD Pack() AS LOGIC
            LOCAL isOk AS LOGIC
            isOk := SUPER:Pack()
            IF isOk
                isOk := SELF:OrderListRebuild()
            ENDIF
            RETURN isOk
            
        PUBLIC METHOD Zap() AS LOGIC
            LOCAL isOk AS LOGIC
            isOk := SUPER:Zap()
            IF isOk
                isOk := SELF:OrderListRebuild()
            ENDIF
            RETURN isOk
            
            #endregion
        #REGION Open, Close, Create
        PUBLIC OVERRIDE METHOD Close() AS LOGIC
            LOCAL orderInfo AS DbOrderInfo
            
            orderInfo := DbOrderInfo{}
            orderInfo:AllTags := TRUE
            SELF:OrderListDelete(orderInfo)
            RETURN SUPER:Close()
            
            
        PUBLIC OVERRIDE METHOD Create( openInfo AS DbOpenInfo ) AS LOGIC
            LOCAL isOk AS LOGIC
            
            isOk := SUPER:Create(openInfo)
            IF  XSharp.RuntimeState.Ansi .AND. isOk
                VAR sig := SELF:_Header:Version
                //SET bit TO Force ANSI Signature
                sig := sig |4
                //Should we also SET the CodePage ??
                //SELF:_Header:DbfCodePage := DbfCodePage.CP_DBF_WIN_ANSI
                SELF:_Header:Version := sig
            ENDIF
            RETURN isOk
            
        METHOD Open(info AS DbOpenInfo) AS LOGIC
            LOCAL lOk AS LOGIC
            lOk := SUPER:Open(info)
            IF lOk
                
                IF RuntimeState.AutoOpen
                    VAR cCdxFileName := System.IO.Path.ChangeExtension(info:FileName, ".CDX")
                    IF System.IO.File.Exists(cCdxFileName)
                        LOCAL orderinfo := DbOrderInfo{} AS DbOrderInfo
                        orderInfo:BagName := cCdxFileName
                        SELF:OrderListAdd(orderInfo)
                    ENDIF
                ENDIF
            ENDIF
            RETURN lOk
            #ENDREGION
            
        #REGION Move
        
        INTERNAL METHOD ReadRecord() AS LOGIC
            RETURN SELF:_ReadRecord()
            
            
        PUBLIC METHOD Seek(seekInfo AS DBSEEKINFO ) AS LOGIC
            LOCAL isOk AS LOGIC
            LOCAL ntxIndex AS CdxTag
            
            isOk := FALSE
            BEGIN LOCK SELF
                ntxIndex := SELF:CurrentOrder
                IF ntxIndex != NULL
                    isOk := ntxIndex:Seek(seekInfo)
                ENDIF
                IF  !isOk 
                    SELF:_DbfError(SubCodes.ERDD_DATATYPE, GenCode.EG_NOORDER )
                ENDIF
            END LOCK
            RETURN isOk
            
        PUBLIC METHOD GoBottom() AS LOGIC
            BEGIN LOCK SELF
                IF SELF:CurrentOrder != NULL
                    RETURN SELF:CurrentOrder:GoBottom()
                ELSE
                    RETURN SUPER:GoBottom()
                ENDIF
            END LOCK
            
        PUBLIC METHOD GoTop() AS LOGIC
            BEGIN LOCK SELF
                IF SELF:CurrentOrder != NULL
                    RETURN SELF:CurrentOrder:GoTop()
                ELSE
                    RETURN SUPER:GoTop()
                ENDIF
            END LOCK
            
        METHOD __Goto(nRec AS LONG) AS LOGIC
            // Skip without reset of topstack
            RETURN SUPER:Goto(nRec)
            
        METHOD GoTo(nRec AS LONG) AS LOGIC
            SELF:GoCold()
            IF SELF:CurrentOrder != NULL
                SELF:CurrentOrder:ClearStack()
            ENDIF
            RETURN SUPER:Goto(nRec)
            
            
        PUBLIC METHOD SkipRaw( move AS LONG ) AS LOGIC
            BEGIN LOCK SELF
                IF SELF:CurrentOrder != NULL
                    RETURN SELF:CurrentOrder:SkipRaw(move)
                ELSE
                    RETURN SUPER:SkipRaw(move)
                ENDIF
            END LOCK
            
            #ENDREGION
            
        #REGION GoCold, GoHot, Flush
        PUBLIC OVERRIDE METHOD GoCold() AS LOGIC
            LOCAL isOk AS LOGIC
            
            isOk := TRUE
            BEGIN LOCK SELF
                IF !SELF:IsHot 
                    RETURN isOk
                ENDIF
                isOk := SELF:_indexList:GoCold()
                IF !isOk
                    RETURN isOk
                ENDIF
                RETURN SUPER:GoCold()
            END LOCK
            
        PUBLIC OVERRIDE METHOD GoHot() AS LOGIC
            LOCAL isOk AS LOGIC
            
            isOk := TRUE
            BEGIN LOCK SELF
                isOk := SUPER:GoHot()
                IF !isOk
                    RETURN isOk
                ENDIF
                RETURN SELF:_indexList:GoHot()
            END LOCK
            
        PUBLIC OVERRIDE METHOD Flush() AS LOGIC
            LOCAL isOk AS LOGIC
            
            isOk := TRUE
            BEGIN LOCK SELF
                isOk := SUPER:Flush()
                RETURN SELF:_indexList:Flush()
            END LOCK
            
        #ENDREGION
    END CLASS    
    
END NAMESPACE
