{$REGION 'Licence'}
{ Copyright 2015 The TensorFlow Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Org. Source:  https://github.com/tensorflow/tensorflow
Org. Docu:    https://www.tensorflow.org
The structure of this Delphi porting was oriented to C# porting by Miguel Deicaza.
C# Source:    https://github.com/migueldeicaza/TensorFlowSharp

Delphi porting version: 1.2

==============================================================================}
{$ENDREGION}
unit TensorFlow.DApiBase;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  TensorFlow.LowLevelAPI, TensorFlow._Helpers;

var

 g_aTFProt: TStrings = Nil;      // <- optional for list protocol

type

/// <summary>
/// TensorFlow Exception
/// </summary>
TFException = class(Exception)
public
  /// <summary>
  /// Initializes a new instance of the <see cref="T:TensorFlow.TFException"/> class with a message.
  /// </summary>
  /// <param name="msg">Message.</param>
  constructor Create(msg: String);  overload;
  constructor Create(msg: TFString); overload;
end;

/// <summary>
/// Holds a block of data, suitable to pass, or retrieve from TensorFlow.
/// </summary>
TFDisposable = class(TInterfacedObject)
 private
   ptr: Pointer;
 protected
		/// <summary>
		/// Must be implemented in subclasses to dispose the unmanaged object, it does
		/// not need to take care of zeroing out the handle, that is done by the Dispose
		/// method inherited from TFDisposable
		/// </summary>
   procedure NativeDispose(hnd: Pointer); virtual; abstract;
 public
   /// <summary>
  	/// Initializes a new instance of the <see cref="T:TensorFlow.TFDisposable"/> class.
  	/// </summary>
   constructor Create; overload;
   /// <summary>
   /// Initializes a new instance of the <see cref="T:TensorFlow.TFDisposable"/> class
   /// from the handle that it will wrap.
   /// </summary>
   constructor Create(hnd: Pointer); overload;
   destructor  Destroy; override;
		/// <summary>
		/// Releases all resource used by the <see cref="T:TensorFlow.TFDisposable"/> object.
		/// </summary>
		/// <remarks>Call Dispose when you are finished using the <see cref="T:TensorFlow.TFDisposable"/>. The
		/// Dispose method leaves the <see cref="T:TensorFlow.TFDisposable"/> in an unusable state. After
		/// calling Dispose, you must release all references to the <see cref="T:TensorFlow.TFDisposable"/> so
		/// the garbage collector can reclaim the memory that the <see cref="T:TensorFlow.TFDisposable"/> was occupying.</remarks>
   procedure Dispose;
   //
   class procedure ObjectDisposedException();
   //
   property  Handle: Pointer read ptr write ptr;
end;

/// <summary>
/// Holds a block of data, suitable to pass, or retrieve from TensorFlow.
/// </summary>
/// <remarks>
/// <para>
/// Use the TFBuffer to blobs of data into TensorFlow, or to retrieve blocks
/// of data out of TensorFlow.
/// </para>
/// <para>
/// There are two constructors to wrap existing data, one to wrap blocks that are
/// pointed to by an IntPtr and one that takes a byte array that we want to wrap.
/// </para>
/// <para>
/// The empty constructor can be used to create a new TFBuffer that can be populated
/// by the TensorFlow library and returned to user code.
/// </para>
/// <para>
/// Typically, the data consists of a serialized protocol buffer, but other data
/// may also be held in a buffer.
/// </para>
/// </remarks>
TFBuffer = class(TFDisposable)
 protected
   procedure NativeDispose(hnd: Pointer); override;
 public
   constructor Create; overload;
   constructor Create(str: TFString); overload;
   destructor  Destroy; override;
end;

/// <summary>
/// Used to track the result of TensorFlow operations.
/// </summary>
/// <remarks>
/// <para>
/// TFStatus is used to track the status of a call to some TensorFlow
/// operations.   Instances of this object are passed to various
/// TensorFlow operations and you can use the <see cref="P:TensorFlow.TFStatus.Ok"/>
/// to quickly check if the operation succeeded, or get more detail from the
/// <see cref="P:TensorFlow.TFStatus.StatusCode"/> and a human-readable text
/// using the <see cref="P:TensorFlow.TFStatus.StatusMessage"/> property.
/// </para>
/// <para>
/// The convenience <see cref="M:TensorFlow.TFStatus.Raise"/> can be used
/// to raise a <see cref="P:TensorFlow.TFException"/> if the status of the
/// operation did not succeed.
/// </para>
/// </remarks>
TFStatus = class(TFDisposable)
 private
   function GetStatusCode(): TF_Code;
   function GetStatusMessage(): TFString;
   function GetOk(): Boolean;
   function GetError(): Boolean;
 protected
   procedure NativeDispose(hnd: Pointer); override;
 public
   constructor Create;
   destructor  Destroy; override;
   procedure   SetStatusCode (code: TF_Code; msg: TFString); overload;
   function CheckMaybeRaise(incoming: TFStatus; last: Boolean = True): Boolean;
   class function Setup(incoming: TFStatus): TFStatus;
   /// <summary>String representation of a class instance.</summary>
   function    ToString(): String; override;
   /// <summary>
   /// Convenience method that raises an exception if the current status is an error.
   /// </summary>
   /// <remarks>
   /// You can use this method as a convenience to raise an exception after you
   /// invoke an operation if the operation did not succeed.
   /// </remarks>
   procedure RaiseEx();
   /// <summary>
   /// Utility function used to simplify implementing the idiom
   /// where the user optionally provides a TFStatus, if it is provided,
   /// the error is returned there; If it is not provided, then an
   /// exception is raised.
   /// </summary>
   property    StatusCode:    TF_Code  read GetStatusCode;
   property    StatusMessage: TFString read GetStatusMessage;
   property    Ok:            Boolean  read GetOk;
   property    Error:         Boolean  read GetError;
end;

procedure ClearTFProt;
procedure WriteTFProt(const txt: String);

implementation

procedure ClearTFProt;
begin
 if Assigned(g_aTFProt) then
   g_aTFProt.Clear;
end;

procedure WriteTFProt(const txt: String);
begin
 if Assigned(g_aTFProt) then
   g_aTFProt.Add(txt);
end;

//------------------------------------------------------------------------------
//----------------------------- TFException ------------------------------------
//------------------------------------------------------------------------------

constructor TFException.Create(msg: String);
begin
 inherited Create(msg);
end;

constructor TFException.Create(msg: TFString);
begin
 inherited Create(String(msg));
end;

//------------------------------------------------------------------------------
//----------------------------- TFDisposable -----------------------------------
//------------------------------------------------------------------------------

constructor TFDisposable.Create;
begin
 inherited Create;
 self.ptr := Nil;
end;

constructor TFDisposable.Create(hnd: Pointer);
begin
 inherited Create;
 self.ptr := hnd;
end;

destructor  TFDisposable.Destroy;
begin
 self.Dispose;
 inherited Destroy;
end;

procedure TFDisposable.Dispose;
begin
 if Assigned(self.ptr) then
   NativeDispose(self.ptr);
 self.ptr := Nil;
end;

class procedure TFDisposable.ObjectDisposedException();
begin
 raise TFException.Create('The object was disposed');
end;

//------------------------------------------------------------------------------
//----------------------------- TFBuffer ---------------------------------------
//------------------------------------------------------------------------------

constructor TFBuffer.Create;
begin
 inherited Create(TF_NewBuffer());
end;

constructor TFBuffer.Create(str: TFString);
var
 lng: TF_size_t;
 l_sTFStr: TFString;
begin
 l_sTFStr := AnsiString(str);
 if Length(l_sTFStr) > 0 then begin
   lng := Length(l_sTFStr);
   inherited Create(TF_NewBufferFromString(@(l_sTFStr[1]),lng));
 end
 else
   inherited Create(TF_NewBufferFromString(PTFChar(''), 0));
end;

destructor  TFBuffer.Destroy;
begin
 inherited Destroy;
end;

procedure TFBuffer.NativeDispose(hnd: Pointer);
begin
 if Assigned(hnd) then
   TF_DeleteBuffer(hnd);
end;

//------------------------------------------------------------------------------
//----------------------------- TFStatus ---------------------------------------
//------------------------------------------------------------------------------

constructor TFStatus.Create;
begin
 inherited Create(TF_NewStatus());
end;

destructor  TFStatus.Destroy;
begin
 inherited Destroy;
end;

procedure TFStatus.NativeDispose(hnd: Pointer);
begin
 if Assigned(hnd) then
   TF_DeleteStatus(hnd);
end;

function TFStatus.GetOk(): Boolean;
begin
 Result := StatusCode = TF_Code.TF_OK;
end;

function TFStatus.GetError(): Boolean;
begin
 Result := StatusCode <> TF_Code.TF_OK;
end;

function TFStatus.CheckMaybeRaise(incoming: TFStatus; last: Boolean = True): Boolean;
var
 l_oEx: TFException;
begin
 if not Assigned(incoming) then begin
   if not Assigned(Handle) then
     WriteTFProt('CheckMaybeRaise: TFStatus.Handle is Nil!');
   if StatusCode <> TF_Code.TF_OK then begin
     l_oEx := TFException.Create(StatusMessage);
     self.DisposeOf;
     raise l_oEx;
   end;
   if last then
     self.DisposeOf;
   Result := True;
 end
 else
   Result := StatusCode = TF_Code.TF_OK;
end;

class function TFStatus.Setup(incoming: TFStatus): TFStatus;
begin
 if Assigned(incoming) then
   Result := incoming
 else
   Result := TFStatus.Create;
end;

function  TFStatus.GetStatusCode(): TF_Code;
begin
 Result := TF_GetCode(Handle);
end;

function  TFStatus.GetStatusMessage(): TFString;
begin
 Result := TFString(TF_Message(Handle));
end;

procedure TFStatus.SetStatusCode(code: TF_Code; msg: TFString);
var
 l_sTFStr: TFString;
begin
 l_sTFStr := TFString(msg);
 TF_SetStatus (Handle, code, _PTFChar(l_sTFStr));
end;

function  TFStatus.ToString(): String;
begin
 Result := Format('[TFStatus: StatusCode=%d, StatusMessage=%s]', [Integer(StatusCode), StatusMessage]);
end;

procedure TFStatus.RaiseEx();
begin
 if TF_GetCode(Handle) <> TF_Code.TF_OK then
   raise TFException.Create(StatusMessage);
end;

end.
