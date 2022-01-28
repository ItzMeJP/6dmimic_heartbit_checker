unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  ExtCtrls, lNetComponents, lNet;

type

  { TForm1 }

  TForm1 = class(TForm)
    Label1: TLabel;
    configGrid: TStringGrid;
    Label2: TLabel;
    Label3: TLabel;
    MemoDebug: TMemo;
    hearbit_signal: TShape;
    MemoDebug2: TMemo;
    Timer: TTimer;
    UDP_heartbit: TLUDPComponent;


    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure TimerStartTimer(Sender: TObject);
    procedure TimerStopTimer(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure UDP_heartbitReceive(aSocket: TLSocket);
    procedure startUDP();
    procedure loadConfig();
    procedure saveConfig();
    procedure processThreshold_ASYNC(Data: PtrInt);
  private

    shutdown_threshold_time_ms: integer;
    heartbit_word : string;


  public
    heartbit_timer_counter_ms: integer;

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }



procedure TForm1.UDP_heartbitReceive(aSocket: TLSocket);
var
  buf : string;
begin
    UDP_heartbit.GetMessage(buf);
    //MemoDebug.Append('UDP datagram received. Content: ' + buf);

    if CompareText(buf,heartbit_word)=0 then
    begin
         //MemoDebug.Append('Heartbit received. Clearing timer count. ' + heartbit_timer_counter_ms.toString());
         MemoDebug2.Clear();
         MemoDebug2.Append('Heartbit received. '+ heartbit_timer_counter_ms.toString());
         hearbit_signal.Brush.Color:=$00FF00;
         heartbit_timer_counter_ms := 0;
    end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin

    heartbit_word := '<b>Heartbit<e>';

    MemoDebug.Clear;
    MemoDebug2.Clear();

    loadConfig();
    startUDP();

    Timer.Interval:=1;
    Timer.Enabled:=True;


    Application.QueueAsyncCall(@processThreshold_ASYNC, 1);

end;

procedure TForm1.TimerStartTimer(Sender: TObject);
begin
  heartbit_timer_counter_ms := 0;
end;

procedure TForm1.TimerStopTimer(Sender: TObject);
begin

end;

procedure TForm1.TimerTimer(Sender: TObject);
begin
     heartbit_timer_counter_ms := heartbit_timer_counter_ms+1;
     //MemoDebug.Append('Without hearbit time elapsed: ' + heartbit_timer_counter_ms.ToString());
end;

procedure TForm1.processThreshold_ASYNC(Data: PtrInt);
begin
   while ( (heartbit_timer_counter_ms < shutdown_threshold_time_ms) )do
    begin
         Application.ProcessMessages;
         if  heartbit_timer_counter_ms > 0.25*shutdown_threshold_time_ms then
         begin
             hearbit_signal.Brush.Color:=$00FFFF;
             MemoDebug2.Clear();
             MemoDebug2.Append('None heartbit received. Timeleft to shutdown: '+ ((shutdown_threshold_time_ms-heartbit_timer_counter_ms)*0.001).toString() + 's');
         end;
         //heartbit_timer_counter_ms := heartbit_timer_counter_ms+1;
         //sleep(100);
    end;

    Timer.Enabled:=False;
    hearbit_signal.Brush.Color:=$0000FF;
    //ShowMessage('Shutdown');
    Form1.Close;

end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  UDP_heartbit.Disconnect();
end;

procedure TForm1.startUDP();
begin
  UDP_heartbit.Host:=configGrid.Cells[1, 0];
  UDP_heartbit.Port:=StrToInt(configGrid.Cells[1, 1]);
  shutdown_threshold_time_ms := StrToInt(configGrid.Cells[1, 2])*1000;

  MemoDebug.Append('Local IP configured: ' + UDP_heartbit.Host);
  MemoDebug.Append('Local Port configured: ' + UDP_heartbit.Port.ToString());
  MemoDebug.Append('Disconection Tolerance Time: ' + (shutdown_threshold_time_ms*0.001).ToString() + 's');

  UDP_heartbit.Listen();
end;


procedure TForm1.loadConfig();
begin
 configGrid.LoadFromCSVFile('config.config',',');
end;

procedure TForm1.saveConfig();
begin

end;

end.



