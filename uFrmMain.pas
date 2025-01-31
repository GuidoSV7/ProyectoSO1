unit uFrmMain;

interface

uses
  uCola,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, Vcl.StdCtrls,
  JPeg,Vcl.ExtCtrls, Vcl.Imaging.GIFImg,Vcl.Imaging.pngimage;

type
  TForm1 = class(TForm)
    MainMenu: TMainMenu;
    Juego1: TMenuItem;
    Jugar: TMenuItem;
    N1: TMenuItem;
    Salir: TMenuItem;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure JugarClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SalirClick(Sender: TObject);
  private
    User   : PCB;       //Para almacenar al personaje del usuario.  Este PCB no se encolar�, y por tanto no lo manipular� el PlanificadorRR.
    enemigo :PCB;
    nave_especial : PCB;
    Q      : Cola;      //Cola del Planificador RR.
    Estado : Integer;   //0=No pasa nada, 1=Muri� el User, 2=Muri� la Nave

    Matriz : Array[1..5,1..5] of PCB;
    Nave_Usuario: Tpngimage;
    Nave_Enemiga: Tpngimage;
    Fin:TPngImage;
    Ganar:TPngImage;

    procedure InitJuego();
    procedure Planificador();
    procedure MoverNave(PRUN:PCB);
    procedure MoverBalaN(PRUN:PCB);
    procedure MoverBalaU(PRUN:PCB);
    procedure MoveNaveEspecial(PRUN:PCB);
    procedure Dibujar(P:PCB);
    procedure Borrar(P:PCB);
    procedure Rectangulo(x,y, Ancho, Alto, Color : Integer);
    function MaxX : Integer;
    function MaxY : Integer;
    //-----------------------
    function getUser:PCB;
    function getEnemigo:PCB;

    //----------
    Procedure CrearMatriz(bloque:PCB);
    Procedure Eliminar_mismo_color_por_la_izquierda(bloque:PCB; I,J:integer);
    Procedure Eliminar_forma_cruz_bloques(bloque:PCB; I,J:integer);
    Procedure Verificar_bloques_a_eliminar(bloque:PCB; I,J:integer);
    Procedure Eliminar_mismo_color_recursivo(bloque: PCB; I, J: integer);
    Procedure Cosas_Visuales;
    //----------
    function Impacto(PRUN1,PRUN2:PCB):boolean;
    function Cantidad_de_bloques_vivos:integer;

  public
    fila,columna:integer;
    bandera_nave_enemiga      : Boolean;
    bandera_nave_enemiga_especial      : Boolean;
    estado_nave_especial: integer;

  end;

var
  Form1: TForm1;

implementation
{$R *.dfm}


procedure TForm1.FormCreate(Sender: TObject);

begin
  Q := Cola.Create;    //Construir (new) la cola del PlanificadorRR.
  Randomize;
  //showMessage(intToStr(GetTickCount));
end;



procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
    p:PCB;
begin
   if(Key = VK_RIGHT) and (user.x+user.Ancho < MaxX) and (Estado = 0)then
   begin
     Borrar(user);
     user.x:=user.x+5;
     canvas.StretchDraw(rect(user.x,user.y,user.x+user.Ancho,user.y+user.Alto),Nave_Usuario);
   end else if(Key=VK_LEFT)and (user.x > 0) and (Estado = 0)then begin
     Borrar(user);
     user.x:=user.x-5;
       canvas.StretchDraw(rect(user.x,user.y,user.x+user.Ancho,user.y+user.Alto),Nave_Usuario);
   end;
   if(Key = VK_UP) and (user.y > (MaxY div 2)+50) and (Estado = 0) then
    begin
     Borrar(user);
     user.y:=user.y-5;
     canvas.StretchDraw(rect(user.x,user.y,user.x+user.Ancho,user.y+user.Alto),Nave_Usuario);
    end;
    if(Key = VK_DOWN) and (user.y+user.Alto <> MaxY) and (Estado = 0) then
    begin
     Borrar(user);
     user.y:=user.y+5;
     canvas.StretchDraw(rect(user.x,user.y,user.x+user.Ancho,user.y+user.Alto),Nave_Usuario);
    end;
   if (Key = VK_SPACE) and (Estado = 0)then
      begin
        p.Ancho:=10;
        p.Alto:=20;
        p.Tipo:=BALAU;
        p.Color:=clBlack;
        p.Retardo:=20;
        p.Hora:=GetTickCount;
        p.y:=user.y-2 - p.Alto;
        p.x:=user.x + (user.Ancho-p.Ancho) div 2 ;
        Dibujar(p);
        Q.Meter(p);
      end;


end;

function TForm1.getEnemigo: PCB;
begin
  Result:= enemigo;
end;

function TForm1.getUser: PCB;
begin
  Result:= User;
end;

procedure TForm1.InitJuego;
var

   bloque: PCB;
   x,y: integer;
begin

  //Cargar Imagenes
  Nave_Usuario := TPngImage.Create;
  Nave_Usuario.LoadFromFile('Imagenes/Nave.png');

  Nave_Enemiga := TPngImage.Create;
  Nave_Enemiga.LoadFromFile('Imagenes/Enemigo.png');

  Fin := TPngImage.Create;
  Fin.LoadFromFile('Imagenes/Fin.png');

  Ganar := TPngImage.Create;
  Ganar.LoadFromFile('Imagenes/Ganar.png');

  fila:= 2;
  columna:= 5;
  user.x:= MaxX div 2;
  user.y:= MaxY - 50;
  user.Ancho:=60;
  user.Alto:=30;
  user.Color:=clBlue;
  user.Dureza:=1;
  //Dibujar(user);
  canvas.StretchDraw(rect(user.x,user.y,user.x+user.Ancho,user.y+user.Alto),Nave_Usuario);
  //introducir una nave a la cola
  enemigo.Tipo:=NAVE;
  enemigo.Alto:=30;
  enemigo.Ancho:=50;
  enemigo.Color:=clRed;
  enemigo.y:=30;
  enemigo.x:= (ClientWidth - enemigo.Ancho) div 2;
  enemigo.Hora:=GetTickCount;
  enemigo.Retardo:=100;
  enemigo.Dureza:=2;
  canvas.StretchDraw(rect(enemigo.x,enemigo.y,enemigo.x+enemigo.Ancho,enemigo.y+user.Alto),Nave_Enemiga);

  //Nave Especial
  nave_especial.Tipo:= NAVE_E;
  nave_especial.Alto:=30;
  nave_especial.Ancho:=50;
  nave_especial.Color:=clRed;
  nave_especial.y:=70;
  nave_especial.x:=( (ClientWidth - nave_especial.Ancho) div 2) + 10;
  nave_especial.Hora:=GetTickCount;
  nave_especial.Retardo:=100;
  nave_especial.Dureza:=1;

  Dibujar(nave_especial);

  Q.Meter(enemigo);
  Q.Meter(nave_especial);
  CrearMatriz(bloque);
  bandera_nave_enemiga:=false;
  bandera_nave_enemiga_especial:=true;
  estado_nave_especial:= 1;


end;



 procedure TForm1.JugarClick(Sender: TObject);
begin
  InitJuego();
  while Estado=0 do
  begin
    Cosas_Visuales;
    Planificador();
    Cantidad_de_bloques_vivos;
    Application.ProcessMessages();
  end;
end;

  function TForm1.Impacto(PRUN1, PRUN2:PCB):Boolean;
  var MitadXPRUN1, MitadYPRUN1,MitadXPRUN2, MitadYPRUN2: integer;
  var Da�o_Boolean:boolean;
  var I,J:integer;
begin
  MitadXPRUN1:= (PRUN1.ancho div 2) + PRUN1.X;
  MitadYPRUN1:= (PRUN1.alto div 2) + PRUN1.Y;
  MitadXPRUN2:= (PRUN2.ancho div 2) + PRUN2.x;
  MitadYPRUN2:= (PRUN2.alto div 2) + PRUN2.y;
  Da�o_boolean:=False;

  //user.Ancho:=50;
  //user.Alto:=20;

 {for I := 1 to PRUN2.Ancho div 2 do
      Begin
        for J := 1 to PRUN2.Alto div 2 do
          Begin
          if (MitadXPRUN1 = MitadXPRUN2+I) and (MitadYPRUN1 = MitadYPRUN2+J)
          or ( MitadXPRUN1= MitadXPRUN2-I) and (MitadYPRUN1 = MitadYPRUN2-J)
          then
            Begin
              Da�o_boolean:=True;
              Break
            End;
          End;
      End;      }


         //usando bounding box (caja delimitadora en espa�ol)

         Result := (PRUN1.x + PRUN1.Ancho > PRUN2.x) and (PRUN1.x < PRUN2.x + PRUN2.ancho) and
            (PRUN1.y+ PRUN1.Alto > PRUN2.y) and (PRUN1.y < PRUN2.y + PRUN2.Alto);

    
end;

//***** Funciones para Manipular los "Gr�ficos".
function TForm1.Cantidad_de_bloques_vivos: integer;
var
  I: Integer;
  J: Integer;
  contador:integer;
begin
   contador:=0;

   for I := 1 to fila do
   begin
     for J := 1 to columna do
      begin
        if(Matriz[I][J].Dureza)>0 then
        begin
          contador := contador+1;
        end;
      end;
   end;

   result:= contador;
end;

procedure TForm1.Cosas_Visuales;
begin
  Label2.Caption := IntToStr(getenemigo.Dureza);
  Label4.Caption := IntToStr(getUser.Dureza);
  Label6.Caption := IntToStr(Cantidad_de_bloques_vivos);
end;

procedure TForm1.CrearMatriz(bloque:PCB);
 var
  x,y, I, J : integer;
begin


  y := 0;

  for I := 1 to fila do
  begin
    x:= 0;
    for J := 1 to columna do
      begin
        bloque.x := x;
        bloque.Ancho:= MaxX div columna;
        bloque.y := (MaxY div 2) + y;
        bloque.Alto := 30;
        bloque.Dureza := 1;
        case Random(3) of
        0:  bloque.Color:=clRed;
        1:  bloque.Color:=clBlue;
        2:  bloque.Color:=clYellow;
        end;
        x:= x+bloque.Ancho;
        Matriz[I,J] := bloque;
        Dibujar(bloque);



      end;
      y:= y +30;
  end;


end;

procedure TForm1.Dibujar(P: PCB);
begin  //Dibuja al PCB P como un rectangulo en la pantalla.
  Rectangulo(P.x, P.y, P.Ancho, P.Alto, P.Color);
end;


procedure TForm1.Eliminar_forma_cruz_bloques(bloque: PCB; I, J: integer);
begin



  if(Matriz[I][J+1].Color = bloque.Color) and (Matriz[I][J+1].Dureza>0) then
  begin
      Borrar(Matriz[I][J+1]);
      Matriz[I][J+1].Dureza := 0;
  end;

  if (Matriz[I][J-1].Color = bloque.Color) and (Matriz[I][J-1].Dureza>0) then
  begin
      Borrar(Matriz[I][J-1]);
      Matriz[I][J-1].Dureza := 0;

  end;

  if (Matriz[I+1][J].Color = bloque.Color) and (Matriz[I+1][J].Dureza>0) then
  begin
      Borrar(Matriz[I+1][J]);
      Matriz[I+1][J].Dureza := 0;


  end;

  if (Matriz[I-1][J].Color = bloque.Color) and (Matriz[I-1][J].Dureza>0) then
  begin
      Borrar(Matriz[I-1][J]);
      Matriz[I-1][J].Dureza := 0;
  end;



end;

procedure TForm1.Eliminar_mismo_color_por_la_izquierda(bloque: PCB; I,
  J: integer);
  var clon_J:integer;
begin


  //While a la inversa para verficar blques para atras

  while clon_J > 0 do
  begin
    if(Matriz[I][clon_J].Color = bloque.Color) and (Matriz[I][clon_J].Dureza>0) then
    begin
      Borrar(Matriz[I][clon_J]);
      Matriz[I][clon_J].Dureza := Matriz[I][clon_J].Dureza -1;

    end;

    if(Matriz[I][clon_J-1].Color <> bloque.Color) then
    begin
      break
    end;

    clon_J:= clon_J -1;

  end;
end;

procedure TForm1.Eliminar_mismo_color_recursivo(bloque: PCB; I, J: integer);
begin
  if (Matriz[I][J].Color <> bloque.Color) or (Matriz[I][J].Dureza = 0) then
    Exit;

  Borrar(Matriz[I][J]);
  Matriz[I][J].Dureza := 0;

  Eliminar_mismo_color_recursivo(bloque, I, J + 1);
  Eliminar_mismo_color_recursivo(bloque, I, J - 1);
  Eliminar_mismo_color_recursivo(bloque, I + 1, J);
  Eliminar_mismo_color_recursivo(bloque, I - 1, J);
end;

procedure TForm1.Borrar(P: PCB);
begin //Dibuja al PCB P como un rectangulo en la pantalla, del mismo color del Form.
  Rectangulo(P.x, P.y, P.Ancho, P.Alto, SELF.Color);
end;


procedure TForm1.Rectangulo(x, y, Ancho, Alto, Color: Integer);
begin   //Dibuja un rectangulo con esquina superior Izq en (x,y).
  Canvas.Pen.Color := Color;
  Canvas.Brush.Color := Color;
  Canvas.Rectangle(x, y, x+Ancho-1, y+Alto-1);
end;


procedure TForm1.SalirClick(Sender: TObject);
begin
  Estado:= 1;

end;

procedure TForm1.Verificar_bloques_a_eliminar(bloque: PCB; I,J:integer);
var clon_J,c1,c2,c3,c4:integer;
begin
  clon_J := J;
  c1:=I;
  c2:=I;
  c3:=J;
  c4:=J;


  {
  //Verificar el resto para la derecha de los bloques.

     for J := J to columna do
     begin
       if(Matriz[I][J].Color <> bloque.Color) then
       begin
         break
       end else if( (Matriz[I][J].Color = bloque.Color) and (bloque.Dureza>0) ) then
       begin
            Eliminar_mismo_color_por_la_izquierda(bloque,I,J);
            borrar(Matriz[I][J]);
            Matriz[I][J].Dureza:= Matriz[I][J].Dureza;
       end;
     end;
                 }

   //Buscar hacia arriba
   while matriz[c1][J].Color = bloque.Color do
   begin
      Eliminar_forma_cruz_bloques(bloque,c1,J);
      c1:=c1+1;
   end;

   //Buscar hacia abajo
   while matriz[c2][J].Color = bloque.Color do
   begin
      Eliminar_forma_cruz_bloques(bloque,c2,J);
      c2:=c2-1;
   end;



   while matriz[I][c3].Color = bloque.Color do
   begin
      Eliminar_forma_cruz_bloques(bloque,I,c3);
      c3:=c3+1;
   end;

   //Buscar hacia la izquierda
   while matriz[I][c4].Color = bloque.Color do
   begin
      Eliminar_forma_cruz_bloques(bloque,I,c4);
      c4:=c4-1;
   end;


end;

function TForm1.MaxX: Integer;
begin
  RESULT := ClientWidth-1;
end;


function TForm1.MaxY: Integer;
begin
  RESULT := ClientHeight-1;
end;


procedure TForm1.MoveNaveEspecial(PRUN: PCB);
var
  bala:PCB;
begin
  Borrar(PRUN);
  if(PRUN.x >= ClientWidth - PRUN.Ancho) and (PRUN.x <=MaxX) then
  begin
    bandera_nave_enemiga_especial:=false;
    estado_nave_especial :=2;
  end;
  if(PRUN.x>=0) and (PRUN.x<=20) then
  begin
    bandera_nave_enemiga_especial:=true;       
    estado_nave_especial:= 4;
  end;

  if(PRUN.y = (MaxY div 2) - PRUN.Alto - 10) and (PRUN.x>20) then
  begin
    estado_nave_especial:= 3;
  end;

  if( PRUN.y = 70) and (PRUN.x<=20)then
  begin
     estado_nave_especial:= 1;
  end;

 






  //if(bandera_nave_enemiga_especial)then
  //begin
  //  PRUN.x:=PRUN.x+5;
  //end else begin
  //  PRUN.x:=PRUN.x-5;
  //end;

  if(estado_nave_especial= 1) then
  begin
     PRUN.x:=PRUN.x+5;
  end;

  if(estado_nave_especial = 2) then
  begin
     PRUN.y:=PRUN.y+5;
  end;

  if(estado_nave_especial = 3) then
  begin
     PRUN.x:=PRUN.x-5;
  end;

  if(estado_nave_especial = 4) then
  begin
     PRUN.y:=PRUN.y-5;
  end;

  //canvas.StretchDraw(rect(PRUN.x,PRUN.y,PRUN.x+PRUN.Ancho,PRUN.y+PRUN.Alto),Nave_Enemiga);
  Dibujar(PRUN);
  PRUN.Hora:=GetTickCount;
  Q.Meter(PRUN);

  if( (Random(40)=0) ) then
  begin
        bala.Dureza:=2;
        bala.Ancho:=30;
        bala.Alto:=30;
        bala.Tipo:=BALAN;
        bala.Color:=clBlack;
        bala.Retardo:=25;
        bala.Hora:=GetTickCount;
        bala.y:=PRUN.y+2 + bala.Alto;
        bala.x:=PRUN.x + (PRUN.Ancho-bala.Ancho) div 2 ;
        Dibujar(bala);
        Q.Meter(bala);
  end;
 
end;

procedure TForm1.MoverBalaN(PRUN: PCB);
var I,J: integer;
    c1,c2:integer;
    bandera, hay_impacto: boolean;
begin
   bandera := true;
   hay_impacto:=false;
   Borrar(PRUN);
   PRUN.y:=PRUN.y+5;
   PRUN.Hora:=GetTickCount;



   //Verificar impacto
   if(hay_impacto = false) then
   begin
     for I := 1 to fila do
     Begin
       for J := 1 to columna do
        Begin
          if Impacto(PRUN,Matriz[I][J]) and (Matriz[I][J].Dureza >0) then
            Begin
              Borrar(Matriz[I][J]);
              Eliminar_mismo_color_recursivo(Matriz[I][J], I,J);
              //Verificar_bloques_a_eliminar(Matriz[I][J], I,J);
              //Eliminar_forma_cruz_bloques(Matriz[I][J],I,J);
              Borrar(PRUN);
              bandera:= false;
              Matriz[I][J].Dureza := 0;
              exit
            End;
        End;
     End;
   end;


   if Impacto(PRUN,User) then
   begin
     Borrar(User);
     User.Dureza:= User.Dureza -1;
     Estado:=1;
     canvas.StretchDraw(rect(0,0,MaxX,MaxY),Fin);
   end else if(PRUN.y <MaxY) and (bandera)then
   begin
    Dibujar(PRUN);
    Q.Meter(PRUN);
   end;



end;

procedure TForm1.MoverBalaU(PRUN: PCB);
var p:PCB;
    c1,c2: integer;
begin
   Borrar(PRUN);
   PRUN.y:=PRUN.y-5;
   PRUN.Hora:=GetTickCount;
   p := Q.sacar();

   //Repintar la matriz
   for c1 := 1 to fila do
   begin
     for c2 := 1 to columna do
      begin
        if(matriz[c1][c2].Dureza >= 1) then
          dibujar(matriz[c1][c2]);
      end;
   end;

   if Impacto(PRUN,p) and (PRUN.Tipo <>  p.Tipo) then
   begin
     p.Dureza:=p.Dureza-1;
     if(P.Tipo = NAVE) then
     begin
       enemigo.Dureza := enemigo.Dureza -1;
     end;
     if(p.Dureza=0) then
     begin
      Borrar(p);
      if(p.Tipo=NAVE) then
        if(getEnemigo.Dureza = 0) then
        begin
        Estado:=2;
        canvas.StretchDraw(rect(0,0,MaxX,MaxY),Ganar);
        end;
        

     end else begin
       Q.Meter(p);
     end;

   end else
   begin
     Q.Meter(p);
     if(PRUN.y >30)then
     begin
      Dibujar(PRUN);
      Q.Meter(PRUN);
     end;
   end;
end;

procedure TForm1.MoverNave(PRUN: PCB);
var
  bala:PCB;
begin
  Borrar(PRUN);
  if(PRUN.x >= ClientWidth - PRUN.Ancho) and (PRUN.x <=MaxX) then
  begin
    bandera_nave_enemiga:=false;
  end else if(PRUN.x>=0) and (PRUN.x<=2) then
  begin
    bandera_nave_enemiga:=true;
  end;

  if ( ((PRUN.x+PRUN.Ancho >= User.x) and (PRUN.x+PRUN.Ancho <=User.x+User.Ancho)) or ((PRUN.x >= User.x) and (PRUN.x <=User.x+User.Ancho)) ) and (Random(30)=0)  then
  begin
    bandera_nave_enemiga:=not(bandera_nave_enemiga);
  end;

  if(bandera_nave_enemiga)then
  begin
    PRUN.x:=PRUN.x+5;
  end else begin
    PRUN.x:=PRUN.x-5;
  end;

  canvas.StretchDraw(rect(PRUN.x,PRUN.y,PRUN.x+PRUN.Ancho,PRUN.y+PRUN.Alto),Nave_Enemiga);
  PRUN.Hora:=GetTickCount;
  Q.Meter(PRUN);
  if( (Random(40)=0) ) then
  begin
        bala.Dureza:=2;
        bala.Ancho:=30;
        bala.Alto:=30;
        bala.Tipo:=BALAN;
        bala.Color:=clBlack;
        bala.Retardo:=25;
        bala.Hora:=GetTickCount;
        bala.y:=PRUN.y+2 + bala.Alto;
        bala.x:=PRUN.x + (PRUN.Ancho-bala.Ancho) div 2 ;
        Dibujar(bala);
        Q.Meter(bala);
  end;
end;

procedure TForm1.Planificador;
  var PRUN: PCB;
begin
  PRUN:=Q.Sacar();
  if(PRUN.Hora+PRUN.Retardo > GetTickCount)then
  begin
    Q.Meter(PRUN);
  end else begin
    case PRUN.Tipo of
    NAVE: MoverNave(PRUN);
    BALAN: MoverBalaN(PRUN);
    BALAU: MoverBalaU(PRUN);
    NAVE_E:MoveNaveEspecial(PRUN);
    end;

  end;


end;

END.
