
#If TARGET<>"android" And TARGET<>"ios" And TARGET<>"glfw" And TARGET<>"stdcpp"
#Error "The brl.filesystem module is not available for current target"
#Endif

Import "native/filesystem.${LANG}"

Extern

Class BBFileSystem

	Function FileType:Int( path:String )
	Function FileSize:Int( path:String )
	Function FileTime:Int( path:String )
	Function CreateFile:Bool( path:String )
	Function DeleteFile:Bool( path:String )
	Function CopyFile:Bool( src:String,dst:String )
	Function CreateDir:Bool( path:String )
	Function DeleteDir:Bool( path:String )
	Function LoadDir:String[]( path:String )
 
End

Private

'A bit icky...
#BRL_GAMETARGET_IMPLEMENTED="0"

Function FixPath:String( path:String )
#If BRL_GAMETARGET_IMPLEMENTED="0"
	Return path
#Else
	Return BBGame.Game().PathToFilePath( path )
#Endif
End

Function _DeleteDir:Bool( path:String )
	Return BBFileSystem.DeleteDir( FixPath( path ) )
End

Function _LoadDir:String[]( path:String )
	Return BBFileSystem.LoadDir( FixPath( path ) )
End

Public

Const FILETYPE_NONE:=0
Const FILETYPE_FILE:=1
Const FILETYPE_DIR:=2

Function FileType:Int( path:String )
	Return BBFileSystem.FileType( FixPath( path ) )
End

Function FileSize:Int( path:String )
	Return BBFileSystem.FileSize( FixPath( path ) )
End

Function FileTime:Int( path:String )
	Return BBFileSystem.FileTime( FixPath( path ) )
End

Function CreateFile:Bool( path:String )
	Return BBFileSystem.CreateFile( FixPath( path ) )
End

Function DeleteFile:Bool( path:String )
	Return BBFileSystem.DeleteFile( FixPath( path ) )
End

Function CopyFile:Bool( src:String,dst:String )
	Return BBFileSystem.CopyFile( FixPath( src ),FixPath( dst ) )
End

Function CreateDir:Bool( path:String )
	Return BBFileSystem.CreateDir( FixPath( path ) )
End

Function DeleteDir:Bool( path:String,recursive:Bool=False )

	If Not recursive Return _DeleteDir( path )
	
	Select FileType( path )
	Case FILETYPE_NONE Return True
	Case FILETYPE_FILE Return False
	End Select
	
	For Local f:String=Eachin _LoadDir( path )

		Local fpath:String=path+"/"+f

		If FileType( fpath )=FILETYPE_DIR
			If Not DeleteDir( fpath,True ) Return False
		Else
			If Not DeleteFile( fpath ) Return False
		Endif
	Next

	Return DeleteDir( path )
End

Function CopyDir:Bool( srcpath:String,dstpath:String,recursive:Bool=False,hidden:Bool=False )

	If FileType( srcpath )<>FILETYPE_DIR Return False

	'do this before create of destdir to allow a dir to be copied into itself!
	'
	Local files:=_LoadDir( srcpath )
	
	Select FileType( dstpath )
	Case FILETYPE_NONE
		If Not CreateDir( dstpath ) Return False
	Case FILETYPE_FILE 
		Return False
	End
	
	For Local f:String=Eachin files
		If Not hidden And f.StartsWith(".") Continue
		
		Local srcp:String=srcpath+"/"+f
		Local dstp:String=dstpath+"/"+f
		
		Select FileType( srcp )
		Case FILETYPE_FILE
			If Not CopyFile( srcp,dstp ) Return False
		Case FILETYPE_DIR
			If recursive And Not CopyDir( srcp,dstp,recursive,hidden ) Return False
		End
	Next
	
	Return True
End

Function LoadDir:String[]( path:String,recursive:Bool=False,hidden:Bool=False )

	Local dirs:=New StringList,files:=New StringList

	If Not path.EndsWith( "/" ) path+="/"
	
	dirs.AddLast ""
	
	While Not dirs.IsEmpty()

		Local dir:String=dirs.RemoveFirst()

		For Local f:String=Eachin _LoadDir( path+dir )
		
			If Not hidden And f.StartsWith(".") Continue
			
			Local p:=dir+f
			
			files.AddLast p
			
			If recursive And FileType( path+p )=FILETYPE_DIR dirs.AddLast p+"/"
		Next
	Wend

	Return files.ToArray()
End

Function StripDir:String( path:String )
	Local i=path.FindLast( "/" )
	If i=-1 i=path.FindLast( "\" )
	If i<>-1 Return path[i+1..]
	Return path
End

Function ExtractDir:String( path:String )
	Local i=path.FindLast( "/" )
	If i=-1 i=path.FindLast( "\" )
	If i<>-1 Return path[..i]
End

Function StripExt:String( path:String )
	Local i=path.FindLast( "." )
	If i<>-1 And path.Find( "/",i+1 )=-1 And path.Find( "\",i+1 )=-1 Return path[..i]
	Return path
End

Function ExtractExt:String( path:String )
	Local i=path.FindLast( "." )
	If i<>-1 And path.Find( "/",i+1 )=-1 And path.Find( "\",i+1 )=-1 Return path[i+1..]
	Return ""
End

Function StripAll:String( path:String )
	Return StripDir( StripExt( path ) )
End
