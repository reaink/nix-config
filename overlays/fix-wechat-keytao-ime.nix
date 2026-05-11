final: prev:

{
  wechat =
    if prev.stdenv.hostPlatform.system != "x86_64-linux" then
      prev.wechat
    else
      let
        pname = "wechat";
        version = "4.1.1.4";

        src = prev.fetchurl {
          url = "https://web.archive.org/web/20260311102439if_/https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
          hash = "sha256-XxAvFnlljqurGPDgRr+DnuCKbdVvgXBPh02DLHY3Oz8=";
        };

        appimageContents = final.appimageTools.extract {
          inherit pname version src;
          postExtract = ''
                        patchelf --replace-needed libtiff.so.5 libtiff.so $out/opt/wechat/wechat

                        mv $out/opt/wechat/RadiumWMPF/runtime/WeChatAppEx \
                          $out/opt/wechat/RadiumWMPF/runtime/WeChatAppEx.real
                        cat > $out/opt/wechat/RadiumWMPF/runtime/WeChatAppEx <<'EOF'
            #!${final.bash}/bin/bash
            export DISPLAY="''${DISPLAY:-:0}"
            export XMODIFIERS="''${XMODIFIERS:-@im=keytao}"
            export GTK_IM_MODULE="''${GTK_IM_MODULE:-xim}"
            export QT_IM_MODULE="''${QT_IM_MODULE:-xim}"
            export GTK_IM_MODULE_FILE="''${GTK_IM_MODULE_FILE:-/usr/lib64/gtk-3.0/3.0.0/immodules.cache}"
            export GDK_BACKEND="''${GDK_BACKEND:-x11}"
            export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-xcb}"

            exec -a "$0" "$0.real" "$@"
            EOF
                        chmod +x $out/opt/wechat/RadiumWMPF/runtime/WeChatAppEx
          '';
        };
      in
      final.appimageTools.wrapAppImage {
        inherit pname version;
        meta = prev.wechat.meta;
        src = appimageContents;

        extraInstallCommands = ''
          mkdir -p $out/share/applications
          cp ${appimageContents}/wechat.desktop $out/share/applications/
          mkdir -p $out/share/icons/hicolor/256x256/apps
          cp ${appimageContents}/wechat.png $out/share/icons/hicolor/256x256/apps/

          substituteInPlace $out/share/applications/wechat.desktop --replace-fail AppRun wechat
        '';
      };
}
