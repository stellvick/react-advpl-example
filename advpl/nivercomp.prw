#include "totvs.ch"

/*{Protheus.doc} u_NiverComp
    Funcao de teste para o TWebEngine/TWebChannel
    @author Ricardo Mansano
    @since 14/08/2019
    @see: http://tdn.totvs.com/display/tec/twebengine
          http://tdn.totvs.com/display/tec/twebchannel
    @observation:
          Compativel com SmartClient Desktop(Qt);
                SmartClient HTML(WebApp);
                SmartClient Electron;
*/
User Function NiverCom()

    local oWebEngine
    private aNiversLocal := {}
    private oWebChannel, oNiverComp

    oDlg := TWindow():New(0, 0, 800, 600, "WebComponent in AdvPL")
        // WebSocket (comunicacao AdvPL x JavaScript)
        oWebChannel := TWebChannel():New()
        oWebChannel:bJsToAdvpl := {|self,key,value| jsToAdvpl(self,key,value) } 
        oWebChannel:connect()
        
        // WebEngine (chromium embedded)
        oWebEngine := TWebEngine():New(oDlg,0,0,100,100,/*cUrl*/,oWebChannel:nPort)
        oWebEngine:Align := CONTROL_ALIGN_ALLCLIENT
        
        // WebComponent de teste
        oNiverComp := NiverComp():Constructor()
        oWebEngine:navigate(;
            iif(oNiverComp:GetOS()=="UNIX", "file://", "")+;
            oNiverComp:mainHTML)
        
        // bLoadFinished sera disparado ao fim da carga da pagina
        // instanciando o bloco de codigo do componente, e tambem um customizado
        oWebEngine:bLoadFinished := {|webengine, url| oNiverComp:OnInit(webengine, url),;
                                                      myLoadFinish(webengine, url) }

    oDlg:Activate("MAXIMIZED")
return

// Funcao customizada que sera disparada apos o termino da carga da pagina
static function myLoadFinish(oWebEngine, url)
    conout("-> myLoadFinish(): Termino da carga da pagina")
    conout("-> Class: " + GetClassName(oWebEngine))
    conout("-> URL: " + url)
    conout("-> TempDir: " + oNiverComp::tmp)
    conout("-> Websocket port: " + cValToChar(oWebChannel:nPort))

    // Executa um runJavaScript
    oWebEngine:runJavaScript("alert('RunJavaScript: Termino da carga da pagina');")
return

// Blocos de codigo recebidos via JavaScript
static function jsToAdvpl(self,key,value)
	conout("",;
		"jsToAdvpl->key: " + key,;
           	"jsToAdvpl->value: " + value)

    // ---------------------------------------------------------------
    // Insira aqui o tratamento para as mensagens vindas do JavaScript
    // ---------------------------------------------------------------
    Do Case 
        case key  == "<submit>" // [*Submit]
            aadd( aNiversLocal, StrTokArr(value, ",") )
            oNiverComp:set("aNivers", aNiversLocal, {|| showNiverItens()} )
    
        case key  == "<delItem>" // [*Delete_Item]
            nItem := val(value) // Indice da linha
            ADel( aNiversLocal, nItem )
            ASize( aNiversLocal, len(aNiversLocal)-1 )
            oNiverComp:set("aNivers", aNiversLocal, {|| showNiverItens()})
    EndCase
Return

// Exibe itens inseridos
static function showNiverItens()
    local i, person, niver
    local aNivers := oNiverComp:get("aNivers")
    local cNiverItens := ""

        // [*LoopCreation]
        for i := 1 to len(aNivers)
            person := aNivers[i,1]
            niver := aNivers[i,2]

            // Constroi a linha, ja com o botao para sua propria delecao 
            // [*Material_UI Lite]
            cNiverItens +=;
            "<div class='divLine'>"+;
                "<button onclick='twebchannel.jsToAdvpl(`<delItem>`," +cValTochar(i)+ ")'>" +;
                    "&#128465;"  +;
                "</button> |"+;
                niver + " | " + person +;
            "</div>"              
        next i

    // "Injeta" itens no DIV HTML (Ajax)
    //oWebEngine:runJavaScript('niver_item.innerHTML="' +cNiverItens+ '"')
    oWebChannel:advplToJS("<niver-new>", cNiverItens)
return

// Classe WebComponent de teste
class NiverComp 
    data mainHTML
    data mainData
    data tmp

    Method Constructor() CONSTRUCTOR
    Method OnInit()     // Instanciado pelo bLoadFinished 
    Method Template()   // HTML inicial
    Method Script()     // JS inicial
    Method Style()      // Style inicial

    Method Get()
    Method Set()

    Method SaveFile(cContent)
    Method GetOS()
endClass

// Construtor
Method Constructor() class NiverComp
    local cMainHTML
    ::tmp := GetTempPath()
    ::mainHTML := ::tmp + lower(getClassName(self)) + ".html"
    ::mainData := {} // Array com as variaveis globais (State)
 
    // ----------------------------------------------------
    // Importante: Compile o twebchannel.js em seu ambiente
    // ----------------------------------------------------
    // Baixa do RPO o arquivo twebchannel.js e salva no TEMP
    // Este arquivo eh responsavel pela comunicacao AdvPL x JS
    h := fCreate(iif(::GetOS()=="UNIX", "l:", "") + ::tmp + "twebchannel.js")
    fWrite(h, GetApoRes("twebchannel.js"))
    fClose(h)

    // HTML principal
    // cMainHTML := ::Script() + chr(10) +;
    //              ::Style() + chr(10) +;
      cMainHTML :=             ::Template()

    // Verifica se o HTML principal foi criado
    if !::SaveFile(cMainHTML)
        msgAlert("Arquivo HTML principal nao pode ser criado")
    endif
return

// Instanciado apos a carga da pagina HTML
Method OnInit(webengine, url) class NiverComp
    // Desabilita pintura evitando refreshs desnecessarios
    webengine:SetUpdatesEnable(.F.)

    // -------------------------------------------------------------------
    // Importante: Acoes que dependam da carga devem ser instanciadas aqui
    // -------------------------------------------------------------------

    // Processa mensagens pendentes e reabilita pintura
    ProcessMessages()
    sleep(300)
    webengine:SetUpdatesEnable(.T.)
return

// Pagina HTML inicial
Method Template() class NiverComp
    Local cJS := GetApoRes("main.8a233def.js")
    Local cCSS := GetApoRes("main.f855e6bc.css")
    Local cHTML := ""
    
    cHTML += ' <!doctype html> '
    cHTML += ' <html lang="en"> '
    cHTML += ' <head> '
    cHTML += '     <meta charset="utf-8" /> '
    cHTML += '     <meta name="viewport" content="width=device-width,initial-scale=1" /> '
    cHTML += '     <meta name="theme-color" content="#000000" /> '
    cHTML += '     <meta name="description" content="Web site created using create-react-app" /> '
    cHTML += '     <title>React App</title> '
    cHTML += '     <style>'
    cHTML += '           body { '
    cHTML += '           -webkit-font-smoothing: antialiased; '
    cHTML += '           -moz-osx-font-smoothing: grayscale; '
    cHTML += '           font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen, Ubuntu, Cantarell, Fira Sans, Droid Sans, Helvetica Neue, sans-serif; '
    cHTML += '           margin: 0 '
    cHTML += '       } '
    cHTML += '        '
    cHTML += '       code { '
    cHTML += '           font-family: source-code-pro, Menlo, Monaco, Consolas, Courier New, monospace '
    cHTML += '       } '
    cHTML += '        '
    cHTML += '       .App { '
    cHTML += '           text-align: center '
    cHTML += '       } '
    cHTML += '        '
    cHTML += '       .App-logo { '
    cHTML += '           height: 40vmin; '
    cHTML += '           pointer-events: none '
    cHTML += '       } '
    cHTML += '        '
    cHTML += '       @media (prefers-reduced-motion:no-preference) { '
    cHTML += '           .App-logo { '
    cHTML += '               animation: App-logo-spin 20s linear infinite '
    cHTML += '           } '
    cHTML += '       } '
    cHTML += '        '
    cHTML += '       .App-header { '
    cHTML += '           align-items: center; '
    cHTML += '           background-color: #282c34; '
    cHTML += '           color: #fff; '
    cHTML += '           display: flex; '
    cHTML += '           flex-direction: column; '
    cHTML += '           font-size: calc(10px + 2vmin); '
    cHTML += '           justify-content: center; '
    cHTML += '           min-height: 100vh '
    cHTML += '       } '
    cHTML += '        '
    cHTML += '       .App-link { '
    cHTML += '           color: #61dafb '
    cHTML += '       } '
    cHTML += '        '
    cHTML += '       @keyframes App-logo-spin { '
    cHTML += '           0% { '
    cHTML += '               transform: rotate(0deg) '
    cHTML += '           } '
    cHTML += '        '
    cHTML += '           to { '
    cHTML += '               transform: rotate(1turn) '
    cHTML += '           } '
    cHTML += '       } '
    cHTML += ' </style> '
    cHTML += ' </head> '
    cHTML += ' <body><noscript>You need to enable JavaScript to run this app.</noscript> '
    cHTML += '     <div id="root"></div> '
    cHTML += '     <script defer="defer">' + cJS + '</script> '
    cHTML += ' </body> '
    cHTML += ' </html> '

return cHTML

// Getter [*Getter_and_Setter]
Method Get(cVarname) class NiverComp
    // Recupera valor do array global (State)
    local nPosBase := AScan( ::mainData, {|x| x[1] == cVarname} )
    if nPosBase > 0
        return ::mainData[nPosBase, 2]
    endif
return ""

// Setter [*Getter_and_Setter]
Method Set(cVarname, xValue, bUpdate) class NiverComp
    // Define/Atualiza valor do array global (State)
    local nPosBase := AScan( ::mainData, {|x| x[1] == cVarname} )
    if nPosBase > 0
        if valType(xValue) == "A"
            ::mainData[nPosBase, 2] := aClone(xValue)
        else
            ::mainData[nPosBase, 2] := xValue
        endif
    else
        Aadd(::mainData, {cVarname, xValue})
    endif
    
    // Dispara bloco de codigo customizado
    // apos atualizacao do valor
    if valtype(bUpdate) == "B"
        eval(bUpdate)
    endif
return

// Salva arquivo em disco
Method SaveFile(cContent) class NiverComp
    local nHdl := fCreate(iif(::GetOS()=="UNIX", "l:", "") + ::mainHTML)
    if nHdl > -1
        fWrite(nHdl, cContent)
        fClose(nHdl)
    else
        return .F.
    endif
return .T.

// Retorna Sistema Operacional em uso
Method GetOS() class NiverComp
    local stringOS := Upper(GetRmtInfo()[2])

    if GetRemoteType() == 0 .or. GetRemoteType() == 1
        return "WINDOWS"
    elseif GetRemoteType() == 2 
        return "UNIX" // Linux ou MacOS		
    elseif GetRemoteType() == 5 
        return "HTML" // Smartclient HTML		
    elseif ("ANDROID" $ stringOS)
        return "ANDROID" 
    elseif ("IPHONEOS" $ stringOS)
        return "IPHONEOS"
    endif    
return ""
