//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//
USING System
USING System.Collections.Generic
USING System.Text
USING XUnit


BEGIN NAMESPACE XSharp.Core.Tests

	CLASS IOTests

		[Fact, Trait("Category", "Misc")]; 
		METHOD FileTest() AS VOID
			Assert.Equal(TRUE,File("c:\windows\system32\shell32.dll"))
			Assert.Equal(FALSE,File(NULL))
		RETURN

	END CLASS
END NAMESPACE // XSharp.Runtime.Tests

