unit Main;

interface //#################################################################### ■

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls,
  LUX, LUX.D2,
  LUX.Delaunay.D2.Periodic,
  LUX.Delaunay.D2.Periodic.Viewer;

type
  TForm1 = class(TForm)
    Viewer1: TPeriDelaunayViewer;
    Panel1: TPanel;
      ButtonC: TButton;
    ButtonAR: TButton;
      ButtonD: TButton;
    ButtonAP: TButton;
    LabelI: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Viewer1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure ButtonCClick(Sender: TObject);
    procedure ButtonARClick(Sender: TObject);
    procedure ButtonAPClick(Sender: TObject);
    procedure ButtonDClick(Sender: TObject);
  private
    { private 宣言 }
    procedure DelaunayChange(Sender: TObject);
  public
    { public 宣言 }
    _Delaunay :TPeriDelaunay2D;
  end;

var
  Form1: TForm1;

implementation //############################################################### ■

uses System.Math;

{$R *.fmx}

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

procedure TForm1.FormCreate(Sender: TObject);
begin
     _Delaunay := TPeriDelaunay2D.Create;

     _Delaunay.Size := 300;  // 基本領域 [0,300)²

     _Delaunay.OnChange.Add( DelaunayChange );

     with Viewer1 do
     begin
          Delaunay := _Delaunay;

          with Camera do
          begin
               SizeX := 2 * _Delaunay.Size;  // 視野は 2L×2L の正方形（3×3 タイルの中央が収まる）
               SizeY := 2 * _Delaunay.Size;
          end;
     end;

     ButtonARClick( Sender );
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
     Viewer1.Delaunay := nil;  // 購読を解除してから解放する

     _Delaunay.OnChange.Del( DelaunayChange );

     _Delaunay.Free;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TForm1.DelaunayChange(Sender: TObject);
begin
     LabelI.Text := 'Poins : ' + _Delaunay.SitesN.ToString + #13#10
                  + 'Faces : ' + _Delaunay.Faces.Count.ToString;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TForm1.Viewer1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
   P :TSingle2D;
   V :TPeriPoin2D;
begin
     P := Viewer1.ScrToTorus( TPointF.Create( X, Y ) );

     if _Delaunay.FindNearPoin( P, V ) < 6
     then _Delaunay.DeletePoin( V )   // 近くに既存点 → 削除
     else _Delaunay.AddPoin   ( P );  // 空白　　　　 → 追加
end;

//------------------------------------------------------------------------------

procedure TForm1.ButtonCClick(Sender: TObject);
begin
     _Delaunay.Clear;
end;

procedure TForm1.ButtonARClick(Sender: TObject);
var
   N :Integer;
   L :Single;
begin
     L := _Delaunay.Size;

     for N := 1 to 10 do _Delaunay.AddPoin( TSingle2D.Create( Random * L, Random * L ) );
end;

procedure TForm1.ButtonAPClick(Sender: TObject);
var
   N :Integer;
   F :TPeriFace2D;
begin
     for N := 1 to 10 do
     begin
          F := _Delaunay.FindMaxCircle;

          if Assigned( F ) then _Delaunay.AddPoin( F.CircumPos );
     end;
end;

procedure TForm1.ButtonDClick(Sender: TObject);
var
   N :Integer;
begin
     for N := 1 to Min( 10, _Delaunay.SitesN ) do
     begin
          _Delaunay.DeletePoin( _Delaunay.SitePoin[ Random( _Delaunay.SitesN ) ] );
     end;
end;

end. //######################################################################### ■
