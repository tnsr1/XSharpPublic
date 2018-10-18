VOSTRUCT _winDDEACK
	MEMBER uBitfield AS WORD

VOSTRUCT _winDDEADVISE
	MEMBER uBitfield 	AS WORD 
	MEMBER cfFormat	AS SHORTINT // RvdH 070411 added

VOSTRUCT _winDDEDATA ALIGN 2		// RvdH 070411 added alignment		
	MEMBER uBitfield AS WORD
	MEMBER  cfFormat AS SHORTINT
	MEMBER  DIM Value[1] AS BYTE

VOSTRUCT _winDDEPOKE ALIGN 2		// RvdH 070411 added alignment
	MEMBER uBitfield AS WORD
	MEMBER cfFormat AS SHORTINT
	MEMBER  DIM Value[1] AS BYTE

VOSTRUCT _winDDELN
	MEMBER ubitfield AS WORD
	MEMBER cfFormat AS SHORTINT

VOSTRUCT _winDdeup  ALIGN 2      // RvdH 070411 added alignment
	MEMBER uBitfield AS WORD
	MEMBER    cfFormat AS SHORTINT
	MEMBER    DIM rgb[1] AS BYTE

_DLL FUNC DdeSetQualityOfService(hwndClient AS PTR,;
	pqosNew AS _winSECURITY_QUALITY_OF_SERVICE,;
	pqosPrev AS _winSECURITY_QUALITY_OF_SERVICE);
	AS LOGIC PASCAL:USER32.DdeSetQualityOfService

_DLL FUNC ImpersonateDdeClientWindow(hWndClient AS PTR, hWndServer AS PTR);
	AS LOGIC PASCAL:USER32.ImpersonateDdeClientWindow

_DLL FUNC PackDDElParam( msg AS DWORD, uINT AS DWORD, uiHi AS DWORD);
	AS LONG PASCAL:USER32.PackDDElParam

_DLL FUNC UnpackDDElParam( msg AS DWORD, lParam AS LONG, puiLo AS DWORD PTR,;
	puihi AS DWORD PTR) AS LOGIC PASCAL:USER32.UnpackDDElParam

_DLL FUNC FreeDDElParam( msg AS DWORD, lParam AS LONG) AS LOGIC PASCAL:USER32.FreeDDElParam

_DLL FUNC ReuseDDElParam(lParam AS LONG, msgIn AS DWORD, msgOut AS DWORD,;
	uiLo AS DWORD, uiHi AS DWORD) AS LONG PASCAL:USER32.ReuseDDElParam


#region defines
DEFINE WM_DDE_FIRST	    := 0x03E0
DEFINE WM_DDE_INITIATE      := (WM_DDE_FIRST)
DEFINE WM_DDE_TERMINATE     := (WM_DDE_FIRST+1)
DEFINE WM_DDE_ADVISE	    := (WM_DDE_FIRST+2)
DEFINE WM_DDE_UNADVISE      := (WM_DDE_FIRST+3)
DEFINE WM_DDE_ACK	    := (WM_DDE_FIRST+4)
DEFINE WM_DDE_DATA	    := (WM_DDE_FIRST+5)
DEFINE WM_DDE_REQUEST	    := (WM_DDE_FIRST+6)
DEFINE WM_DDE_POKE	    := (WM_DDE_FIRST+7)
DEFINE WM_DDE_EXECUTE	    := (WM_DDE_FIRST+8)
DEFINE WM_DDE_LAST	    := (WM_DDE_FIRST+8)
#endregion