--[[   //  S5Hook  //  by yoq  // v1.4b

    S5Hook.AddArchive(string path [, bool precedence])          Add a bba/s5x archive to the internal filesystem
                                                                 - if precedence is true all files will be loaded from it if they are inside
                                                                 
    S5Hook.Log(string textToLog)                                Writes the string textToLog into the Settlers5 logfile
                                                                 - In MyDocuments/DIE SIEDLER - DEdK/Temp/Logs/Game/XXXX.log
    
    S5Hook.ChangeString(string identifier, string newString)    Changes the string with the given identifier to newString
                                                                 - ex: S5Hook.ChangeString("names/pu_serf", "Minion")  --change pu_serf from names.xml

    S5Hook.ReloadCutscenes()                                    Reload the cutscenes in a usermap after a savegame load.
                                                                 - call AFTER AddArchive()
    
    S5Hook.LoadGUI(string pathToXML)                            Load a GUI definition from a .xml file.
                                                                 - call after AddArchive() for files inside the s5x archive
                                                                 - Completely replaces the old GUI --> Make sure all callbacks exist in the Lua script
                                                                 - Do NOT call this function in a GUI callback (button, chatinput, etc...)
                                                                 
    S5Hook.Eval(string luaCode)                                    Parses luaCode and returns a function, can be used to build a internal debugger
                                                                 - ex: myFunc = S5Hook.Eval("Message('Hello world')")
                                                                       myFunc()
                                                                       
    S5Hook.ReloadEntities()                                        Reloads all entity definitions, not the entities list -> only modifications are possible
                                                                 - In general: DO NOT USE, this can easily crash the game and requires extensive testing to get it right
                                                                 - Requires the map to be added with precedence
                                                                 - Only affects new entities -> reload map / reload savegame
                                                                 - To keep savegames working, it is only possible to make entities more complex (behaviour, props..)
                                                                   do not try to remove props/behaviours (ex: remove darios hawk), this breaks simple savegame loading
    
    S5Hook.SetSettlerMotivation(eID, motivation)                Set the motivation for a single settler (and only settlers, crashes otherwise ;)
                                                                 - motivation 1 = 100%, 0.2 = 20% settlers leaves
                                                                 
    S5Hook.GetWidgetPosition(widget)                            Gets the widget position relative to its parent
                                                                - return1: X
                                                                - return2: Y
                                                                
    S5Hook.GetWidgetSize(widget)                                Gets the size of the widget
                                                                - return1: width
                                                                - return2: height
                                                                
    S5Hook.IsValidEffect(effectID)                              Checks whether this effectID is a valid effect, returns a bool
    
    S5Hook.SetPreciseFPU()                                      Sets 53Bit precision on the FPU, allows accurate calculation in Lua with numbers exceeding 16Mil,
                                                                however most calls to engine functions will undo this. Therefore call directly before doing a calculation 
                                                                in Lua and don't call anything else until you're done.

    S5Hook.CreateProjectile(                                    Creates a projectile effect, returns an effectID, which can be used with Logic.DestroyEffect()
                            int effectType,         -- from the GGL_Effects table
                            float startX, 
                            float startY, 
                            float targetX, 
                            float targetY 
                            int damage = 0,         -- optional, neccessary to do damage
                            float radius = -1,      -- optional, neccessary for area hit
                            int targetId = 0,       -- optional, neccessary for single hit
                            int attackerId = 0,     -- optional, used for events & allies when doing area hits
                            fn hitCallback)         -- optional, fires once the projectile reaches the target, return true to cancel damage events
                            
                                                                Single-Hit Projectiles:
                                                                    FXArrow, FXCrossBowArrow, FXCavalryArrow, FXCrossBowCavalryArrow, FXBulletRifleman, FXYukiShuriken, FXKalaArrow

                                                                Area-Hit Projectiles:
                                                                    FXCannonBall, FXCannonTowerBall, FXBalistaTowerArrow, FXCannonBallShrapnel, FXShotRifleman
    
    
    S5Hook.GetTerrainInfo(x, y)                                 Fetches info from the HiRes terrain grid
                                                                 - return1: height (Z)
                                                                 - return2: blocking value, bitfield
                                                                 - return3: sector nr

      
    MusicFix: allows Music.Start() to use the internal file system
            S5Hook.PatchMusicFix()                                      Activate
            S5Hook.UnpatchMusicFix()                                    Deactivate
                                                                         - ex: crickets as background music on full volume in an endless loop
                                                                               S5Hook.PatchMusicFix()
                                                                               Music.Start("sounds/ambientsounds/crickets_rnd_1.wav", 127, true)
                                                                             
                            
    RuntimeStore: key/value store for strings across maps 
            S5Hook.RuntimeStore(string key, string value)                 - ex: S5Hook.RuntimeStore("addedS5X", "yes")
            S5Hook.RuntimeLoad(string key)                                 - ex: if S5Hook.RuntimeLoad("addedS5X") ~= "yes" then [...] end
                            
    CustomNames: individual names for entities
            S5Hook.SetCustomNames(table nameMapping)                    Activates the function
            S5Hook.RemoveCustomNames()                                  Stop displaying the names from the table
                                                                         - ex: cnTable = { ["dario"] = "Darios new Name", ["erec"] = "Erecs new Name" }
                                                                               S5Hook.SetCustomNames(cnTable)
                                                                               cnTable["thief1"] = "Pete"        -- works since cnTable is a reference
    KeyTrigger: Callback for ALL keys with KeyUp / KeyDown
            S5Hook.SetKeyTrigger(func callbackFn)                       Sets callbackFn as the callback for key events
            S5Hook.RemoveKeyTrigger()                                   Stop delivering events
                                                                         - ex: S5Hook.SetKeyTrigger(function (keyCode, keyIsUp)
                                                                                    Message(keyCode .. " is up: " .. tostring(keyIsUp))
                                                                               end)

    CharTrigger: Callback for pressed characters on keyboard
            S5Hook.SetCharTrigger(func callbackFn)                      Sets callbackFn as the callback for char events
            S5Hook.RemoveCharTrigger()                                  Stop delivering events
                                                                         - ex: S5Hook.SetCharTrigger(function (charAsNum)
                                                                                    Message("Pressed: " .. string.char(charAsNum))
                                                                               end)

    MemoryAccess: Direct access to game objects
            S5Hook.GetEntityMem(int eID)                                Gets the address of a entity object
            S5Hook.GetRawMem(int ptr)                                   Gets a raw pointer
            val = obj[n]                                                Dereferences obj and returns a new address: *obj+4n
            shifted = obj:Offset(n)                                     Returns a new pointer, shifted by n: obj+4n
            val:GetInt(), val:GetFloat(), val:GetString()               Returns the value at the address
            val:SetInt(int newValue), val:SetFloat(float newValue)      Write the value at the address
            val:GetByte(offset), val:SetByte(offset, newValue)          Read or Write a single byte relative to val
            S5Hook.ReAllocMem(ptr, newSize)                             realloc(ptr, newSize), call with ptr==0 to use like malloc()
            S5Hook.FreeMem(ptr)                                         free(ptr)
                                                                         - ex: eObj = S5Hook.GetEntityMem(65537)
                                                                               speedFactor = eObj[31][1][7]:GetFloat()
                                                                               name = eObj[51]:GetString() 

    OnScreenInformation (OSI): 
        Draw additional info near entities into the 3D-View (like healthbar, etc).
        You have to set a trigger function, which will be responsible for drawing 
        all info EVERY frame, so try to write efficient code ;)
        
            S5Hook.OSILoadImage(string path)                            Loads a image and returns an image object
                                                                         - Images have to be reloaded after a savegame load
                                                                         - ex: imgObj = S5Hook.OSILoadImage("graphics\\textures\\gui\\onscreen_emotion_good")

            S5Hook.OSIGetImageSize(imgObj)                              Returns sizeX and sizeY of the given image
                                                                         - ex: sizeX, sizeY = S5Hook.OSIGetImageSize(imgObj)

            S5Hook.OSISetDrawTrigger(func callbackFn)                   callbackFn(eID, bool active, posX, posY) will be called EVERY frame for every 
                                                                           currently visible entity with overhead display, the active parameter become true
                                                                           
            S5Hook.OSIRemoveDrawTrigger()                               Stop delivering events

        Only call from the DrawTrigger callback:
            S5Hook.OSIDrawImage(imgObj, posX, posY, sizeX, sizeY)       Draw the image on the screen. Stretching is allowed.
            
            S5Hook.OSIDrawText(text, font, posX, posY, r, g, b, a)      Draw the string on the screen. Valid values for font range from 1-10.
                                                                        The color is specified by the r,g,b,a values (0-255).
                                                                        a = 255 is maximum visibility
                                                                        Standard S5 modifiers are allowed inside text (@center, etc...)
        Example:
        function SetupOSI()
            myImg = S5Hook.OSILoadImage("graphics\\textures\\gui\\onscreen_emotion_good")
            myImgW, myImgH = S5Hook.OSIGetImageSize(myImg)
            S5Hook.OSISetDrawTrigger(cbFn)
        end

        function cbFn(eID, active, x, y)
            if active then
                S5Hook.OSIDrawImage(myImg, x-myImgW/2, y-myImgH/2 - 40, myImgW, myImgH)
            else
                S5Hook.OSIDrawText("eID: " .. eID, 3, x+25, y, 255, 255, 128, 255)
            end
        end                                                        
    
    Set up with InstallS5Hook(), this needs to be called again after loading a savegame.
    S5Hook only works with the newest patch version of Settlers5, 1.06!
    S5Hook is available immediately, but check the return value, in case the player has a old patchversion.
]]

function InstallHook(installedCallback) -- for compatability with v0.10 or older 
    if InstallS5Hook() then installedCallback() end
end


function InstallS5Hook()
    if nil == string.find(Framework.GetProgramVersion(), "1.06.0217") then
        Message("Error: S5Hook requires version patch 1.06!")
        return false
    end
    
    if not __mem then __mem = {}; end
    __mem.__index = function(t, k) return __mem[k] or __mem.cr(t, k); end
    
    local stage0     = "galijmdkifianboanboiilYgkCfdlimmShgianboanboippQidmeIppnagbmhBhedohiianbcbnbcjilBppgaQ"
    local stage1     = "kapenpkbAiemahfclfafegkeagiAlageAgiAQeaAppVfiQhgAifmafihecmppVieShgAkdpanpkbAmgFpenpkbABgkDfdppVmmShgAfjfjileiElpAAkcAinhaIpdkeppQmd"
    local S5HookData = "ojCkcAfiRAAfddfeigpgpglAcfhdKAckRkcAGechcgfgbglAhdDkcAOfagbhegdgienhfhdgjgdeggjhiAefDkcAQffgohagbhegdgienhfhdgjgdeggjhiAfjEkcANepfdejemgpgbgeejgngbghgfAkjEkcAQepfdejehgfheejgngbghgffdgjhkgfAnpEkcANepfdejeehcgbhhejgngbghgfAdgFkcAMepfdejeehcgbhhfegfhiheAjcFkcASepfdejfdgfheeehcgbhhfehcgjghghgfhcAliFkcAVepfdejfcgfgngphggfeehcgbhhfehcgjghghgfhcAfpGkcANfchfgohegjgngffdhegphcgfAjlGkcAMfchfgohegjgngfemgpgbgeAniGkcANedgigbgoghgffdhehcgjgoghANHkcAEemgpghAckHkcALebgegeebhcgdgigjhggfAhjHkcAQfcgfgmgpgbgeedhfhehdgdgfgogfhdAkaHkcAIemgpgbgeehffejAmaHkcAFefhggbgmAohHkcAPfdgfheedhfhdhegpgneogbgngfhdARIkcASfcgfgngphggfedhfhdhegpgneogbgngfhdAnpIkcAPfdgfheedgigbhcfehcgjghghgfhcAkpIkcASfcgfgngphggfedgigbhcfehcgjghghgfhcAhlJkcAOfdgfheelgfhjfehcgjghghgfhcAelJkcARfcgfgngphggfelgfhjfehcgjghghgfhcAddKkcAUfdgfheengphfhdgfeegphhgofehcgjghghgfhcApjJkcAXfcgfgngphggfengphfhdgfeegphhgofehcgjghghgfhcAkmKkcAVfdgfhefdgfhehegmgfhcengphegjhggbhegjgpgoApbKkcAPfcgfgmgpgbgeefgohegjhegjgfhdAddLkcASehgfhefhgjgeghgfhefagphdgjhegjgpgoAeoLkcAOehgfhefhgjgeghgfhefdgjhkgfAgjLkcARedhcgfgbhegffahcgpgkgfgdhegjgmgfAoeMkcAOejhdfggbgmgjgeefgggggfgdheAekNkcAPehgfhefegfhchcgbgjgoejgogggpAooOkcANehgfheefgohegjhehjengfgnAWPkcAKehgfhefcgbhhengfgnAlhQkcALfcgfebgmgmgpgdengfgnAodQkcAIeghcgfgfengfgnAkpQkcAOfdgfhefahcgfgdgjhdgfegfaffAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgiAAkcAgiLAkcAoiceAAAoifaOAAlibpkkeaAmgAojmheaBnhgggbAlihgkkeaAmgAojmheaBjigggbAmdfgfhilheceMilhmceQgkAppdgidmgFfgPlgegppBmgfhfdoipakolhppiddoAhfogfpfomcIAkbmnCkcAifmahecckdkeUhgAmhFmnCkcAAAAAmhFjoggejAilpaifpgggmhFkcggejAhehgdbmamdiddnmnCkcAAhfchkbkeUhgAkdmnCkcAmhFkeUhgAdmEkcAlijoggejAmgAojeamhADjnfiAmgeaEjadbmamdijmgifpgPifpegckhppilheceIgaibomcmBAAijofilNiipaiiAilBffinfnEfdfgppfaUifmahefofgoinllgjoppflfapphfApphfEgiAnghgAgiABAAinhfIfgoimfhilcppidmeYgkAfgkbMjpifApphaMppViiUhgAijmgifpghebmpphfEgkCfgppVUVhgAibmecmBAAijheceEgbojhlgckhppfaoilnoflcppfiibmecmBAAgbojnogckhppgkCppheceIppVcaVhgAifmaheHfaoijkoflcppfippcfmnCkcAloppAAAfgfgfgfgidomQnjoinjfmceMnjoinjfmceInjoonjfmceEnjoonjbmcegkBfdppVmmShgAidmeIfagkcioipbdmlkppfjijmboioakeldppfafdppVmaShgAidmeIijnodbmaeamdidomIijofgkBfdppVnaShgAidmeIijmbffidmfEffoiimkfldppnjefpmnjefAoifaGAAoielGAAidmeIliCAAAmdidomQijofgkCfdppVcaShgAgkDfdppVcaShgAgkEfdppVcaShgAgkFfdppVcaShgAnjfnMnjfnInjfnEnjfnAffgkAgkBfdppVnaShgAidmeIfaoidcgkldppijmboidhgmldppidmedadbmamdidomQijofgkCfdppVcaShgAppeeceEidhmceEJhfopidmeInlfnMnlfnInlfnEnlfnAgkAgkAffgkAfanjbmcefanjbmcegkAfanlbmcegkBfdppVmmShgAidmeIfaoinggjldppijmboiffhcldppidmeQdbmamdgipanippppfdppVdeShgAkdnbCkcAidmeIlihlWfeAmgAojeamhAhcopenAdbmamdkbnbCkcAifmahecofagipanippppfdppVdmShgAidmeMmhFhlWfeAffilomfgmhFhpWfeAfhilhnMmhFnbCkcAAAAAdbmamdffijoffgfhgailbnjmdkifAppdfnbCkcAgipanippppfdppVdiShgAilefMnleaeeoiGFAAdbmadiifHCAAPjfmafafdppVkiShgAilefInjeaEnjAoiogEAAoiobEAAgkAgkAgkEfdppVmiShgAgkAfdppVlaShgAidmecmgbojcbQlcppfgildfpanpkbAgkBfdppVmmShgAfafgppVfmShgAgkCfdppVmmShgAfafgppVfmShgAgipanippppfgppVfeShgAidmecifodbmamdfgildfpanpkbAgkBfdppVmmShgAfafgppVfmShgAgipanippppfgppVliShgAgkppfgppVmmShgAfafdppVfmShgAidmecifodbmaeamdgkCfdppVmmShgAidmeIfaoijjicllppfjfagkBfdppVmmShgAidmeIfaoidaggldppfkfkileeceomileaYijUiidbmamdgkBfdppVmmShgAidmeIfagiHAkcAoieehllcppidmeIdbmamdgagkBfdppVmmShgAgkBfaoigffhlcppgkCfdppVkmShgAidmeYifmaheFoiEAAAgbdbmamdildfiipaiiAineoEoifkljljppijmhepilegIppdeliilemlipmijMliephfpgipAmdgkBfdppVmmShgAidmeIifmaheDfaolFgipmjphhAkbemdekaAilIilBppfaMdbmamdgagkAgkBfdppVmmShgAidmeIfaoiXfmldppijmboikifmldppgbdbmamdgkAgkBfdppVmmShgAidmeIfafaoimlVlkppijeeceEfdppVkeShgAidmeQdbmaeamdliRpjfdAmgAojmheaBdePeoAmgeaonolgipanippppfdppVdeShgAkdnfCkcAidmeIdbmamdkbnfCkcAifmahecnfagipanippppfdppVdmShgAidmeMliRpjfdAmgAoimheaBGpfpoppmgeaonhemhFnfCkcAAAAAdbmamdiliamiAAAifmaheelfhijmhilbnjmdkifAgkAfdppVlaShgAppdfnfCkcAgipanippppfdppVdiShgAfhfdppVfmShgAgkpofdppVliShgAgkppfdppVmmShgAidmecmfpllAAAAdjnihfKoiclohlappojhepalbppfjojgopalbppkbnjCkcAifmahecefagipanippppfdppVdmShgAidmeMmhFenhfeaApihaUAmhFnjCkcAAAAAdbmamdgipanippppfdppVdeShgAkdnjCkcAidmeIlienhfeaAmhAlajdgbAdbmamdgailbnjmdkifAppdfnjCkcAgipanippppfdppVdiShgAnleeceMnnfmcepiidomIfdppVmeShgAgkAgkAgkBfdppVmiShgAgkAfdppVlaShgAidmedagbojponmlcppkbnnCkcAifmahecefagipanippppfdppVdmShgAidmeMmhFhohfeaAknhcUAmhFnnCkcAAAAAdbmamdgipanippppfdppVdeShgAkdnnCkcAidmeIlihohfeaAmhAbljegbAdbmamdgaijmpilbnjmdkifAppdfnnCkcAgipanippppfdppVdiShgAnleeceMnnfmcepiidomIfdppVmeShgAijpilbCpgpbiioafafdppVkiShgAgkAgkAgkCfdppVmiShgAgkAfdppVlaShgAidmedigbojdgnolcppkbobCkcAifmahecofagipanippppfdppVdmShgAidmeMmhFiokfffAmhegECmhFjckfffAAAAolmhFobCkcAAAAAdbmamdgipanippppfdppVdeShgAkdobCkcAidmeIliiokfffAmgAojeamhAmggeemAdbmamdmhegECAAAgailbnjmdkifAppdfobCkcAgipanippppfdppVdiShgAilefQnleaQnnfmcepiidomIfdppVmeShgAgkAgkAgkBfdppVmiShgAgkAfdppVlaShgAidmedagbojojjkldppgagkBfdoimmlclhppfaoipjbklgppifmahecoiniileAAAllHdaBAfdfdijodfdidmdEfdoiggdflgppilhjQilhpEgkCfgppVcaShgAnjfpYidmeQgbdbmamdkbgaopieAiliafiCAAileaMfaoijcipljppdbmamdgkBfdoiCkdldppfaoifnhjldppijmboiejholdppidmeImdnnfmcepiidomIfdppVmeShgAidmeMmdoinappppppnjeaYnjeaUoinoppppppoinjppppppliCAAAmdoilfppppppnjeacanjeabmoimdppppppoiloppppppliCAAAmdgailfmceceidomeiijofdbmaljeiAAAiieeNppejhfpjmhefAjieghhAfdppVlmShgAfoijmggkBoileAAAgkCoiknAAAgkDoikgAAAgkEoijpAAAgkFoijiAAAnjfncenjfncanjffbmnjfnUnjffYnjfnQnlfnEidooFheddgkGoihhAAAnlfndeeohecggkHoigkAAAnjfndieohecagkIoifnAAAnlfndaeoheTgkJoifaAAAnlfncmolHmhefdiAAialpffilNkmfnijAilBppfafmfaidooChibpilhecenmgipanippppfdppVdeShgAijegfiidmeIppdgoicgAAAijGnlEceoinppoppppfiidmeeigbliBAAAmdppheceEfdppVcaShgAidmeImcEAfgilheceIgkdaoiXdflkppfpijhacmijmhljcmAAApdkemheaceicMkcAfomcEAgailbnjmdkifAfbpphbfigipanippppfdppVdiShgAppVdmShgAgkAgkBgkAfdppVmiShgAgkppfdppVkmShgAijmggkAfdppVlaShgAidmecmfjilBilhicmijdjfaoifmcblkppfiifpghfGgbilBppgacegbilBgkBppQmdgailfmcecegkBfdoijalalhppfailNeeibijAoimajnknppPlgmafafdppVkiShgAidmeIgbliBAAAmdkbkmfnijAilhacegkBfdoihhlalhppnjfnAgkCfdoigmlalhppnjfnEinenIffoioieolgpppphfMpphfIileoEoiLjakcppifmamdgailfmceceidomQijofoiljpppppphefoileobmilefMeaPkpebbmDefIilfbIineeecCPlhAfafdoihblalhppkbomibifAileaYileiEilefMPkpFheilijADefIPlgEBfafdoieolalhpppphfMpphfIoiljgglfppfafdoidmlalhppidmeQgbliDAAAmdidmeQgbdbmamdhddfgmhfgbdfAgmhfgbfphdgfhegngfhegbhegbgcgmgfAgmhfgbfpgogfhhhfhdgfhcgegbhegbAgmhfgbemfpgfhchcgphcAgimaNkcAppVniQhgAgioiNkcAfaginiNkcAfagimhNkcAfappVniRhgAkdAnlkbAppVniRhgAkdEnlkbAppVniRhgAkdInlkbAmdcpQkcAHehgfheejgoheAVQkcAJehgfheeggmgpgbheAekQkcAIehgfheechjhegfApiPkcAHfdgfheejgoheAnlPkcAJfdgfheeggmgpgbheAhaQkcAIfdgfheechjhegfAjeQkcAKehgfhefdhehcgjgoghAipPkcADgdhcAlfPkcAHepgggghdgfheAAAAAfpfpgngfgnAhfhdgfcadkAgikhOkcAgidcOkcAoifkpeppppgikhOkcAfdoifakplhppgiopnippppfdppViaShgAgipanippppfdppVdeShgAkdofCkcAidmeQmdgailfmcecegkBfdoiigkolhppfaoildWlgppifmahfEgbdbmamdfaoicbAAAgbliBAAAmdgailfmcecegkBfdoifokolhppfaoiHAAAgbliBAAAmdilheceEgkIfdppVEnlkbAinfaEijQijdcolPilheceEgkEfdppVEnlkbAijdappdfofCkcAgipanippppfdppVdiShgAgkpofdppVAnlkbAidmebmmcEAgkBfdoiebkolhppifmaheBmdgiknOkcAfdppVInlkbAgailfmceceoinnppppppildaildggkCfdoinmknlhppinEigfaoijippppppgbliBAAAmdgailfmceceoilhppppppildaildggkCfdoilgknlhppinEigfaoifmppppppgbliBAAAmdgailfmceceoijbppppppildagkCfdoikkknlhppnjbogbliAAAAmdgailfmceceoiheppppppildagkCfdoihfknlhppijGgbliAAAAmdgailfmceceoifhppppppilAnjAoipjpkppppgbliBAAAmdgailfmceceoidnppppppilAppdafdoikiknlhppgbliBAAAmdgailfmceceoiccppppppildagkCfdoicdknlhppPlgEdafafdoiicknlhppgbliBAAAmdgailfmceceoipmpoppppildagkCfdoipnkmlhppBmggkDfdoipdkmlhppiiGgbdbmamdgailfmceceoinipoppppilAppdafdoihfknlhppgbliBAAAmdoijnhdlkppdbmamdgailfmcecegkCfdoilnkmlhppfagkBfdoilekmlhppfaoimadalkppfjfjfafdoiPknlhppgbliBAAAmdgailfmcecegkBfdoijbkmlhppfaoidhbnlkppfjgbdbmamdinlokeCAAgailbnjmdkifAoicbAAAgbojSjjjopplimakchcAgailbnjmdkifAoiKAAAgbojfbjjjoppmmdbmamdoiSpcppppoiiapeppppoinepgppppoignphppppoiEpippppoiknpippppmdoikbpmppppoifmpnppppmd"
    
    local shrink = function(cc)
        local o, n, max = {}, 1, string.len(cc)
        while n <= max do
            local b = string.byte(cc, n)
            if b >= 97 then b=16*(b-97)+string.byte(cc, n+1)-97; n=n+2; else b=b-65; n=n+1; end
            table.insert(o, string.char(b))
        end
        return table.concat(o)
    end
    
    Mouse.CursorHide()
    for i = 1, 37 do Mouse.CursorSet(i); end
    Mouse.CursorSet(10)
    Mouse.CursorShow() 
    
    local csPath = "Config\\User\\Callsign"
    local callSign = GDB.GetString(csPath)
    GDB.SetStringNoSave(csPath, shrink(stage0))
    
    local eID = Logic.CreateEntity(Entities.XD_Plant1, 0, 0, 0, 0)
    XNetwork.Manager_GetLocalMachineUserName()
    Logic.SetEntityScriptingValue(eID, -58, 4582799)
    Logic.DestroyEntity(eID, shrink(stage1), shrink(S5HookData))
    
    GDB.SetStringNoSave(csPath, callSign)
    
    return S5Hook ~= nil
end