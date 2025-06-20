#Requires AutoHotkey v2.0
;Copilot modded code from https://www.autohotkey.com/boards/viewtopic.php?t=119211
#SingleInstance Force

; ———————————————————————————————————————————————
; Конфигурация
; ———————————————————————————————————————————————
targetExe     := "WsaClient.exe"
idleThreshold := 5       ; 5 × 500ms = 2.5 секунды
lastX := 0, lastY := 0
idleCount := 0
cursorHidden := false

; ———————————————————————————————————————————————
; Инициализация
; ———————————————————————————————————————————————
OnExit(*) => SystemCursor("Show")
SystemCursor("Reload")
SetTimer(TrackIdleCursor, 500)
return

; ———————————————————————————————————————————————
; Таймер: отслеживание активности курсора в окне WSA
; ———————————————————————————————————————————————
TrackIdleCursor() {
    global lastX, lastY, idleCount, idleThreshold, cursorHidden, targetExe

    hwnd := WinExist("A")
    if hwnd && WinGetProcessName(hwnd) = targetExe {
        MouseGetPos &x, &y
        if (x = lastX && y = lastY) {
            idleCount++
            if (!cursorHidden && idleCount >= idleThreshold) {
                SystemCursor("Hide")
                cursorHidden := true
            }
        } else {
            lastX := x, lastY := y
            idleCount := 0
            if cursorHidden {
                SystemCursor("Show")
                cursorHidden := false
            }
        }
    } else {
        if cursorHidden {
            SystemCursor("Show")
            cursorHidden := false
        }
        idleCount := 0
    }
}

; ———————————————————————————————————————————————
; Горячая клавиша: Win+C — вручную скрыть/показать курсор
; ———————————————————————————————————————————————
#c::SystemCursor("Toggle")

; ———————————————————————————————————————————————
; Функция управления курсором
; cmd = "Show" | "Hide" | "Toggle" | "Reload"
; ———————————————————————————————————————————————
SystemCursor(cmd) {
    static visible := true
    static loaded := false
    static cursors := Map()
    static ids := [32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650]

    if (cmd = "Reload" || !loaded) {
        loaded := true
        cursors := Map()
        for id in ids {
            hOrig := DllCall("LoadCursor", "Ptr", 0, "Ptr", id, "Ptr")
            hDefault := DllCall("CopyImage", "Ptr", hOrig, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0, "Ptr")
            andMask := Buffer(128, 0xFF)
            xorMask := Buffer(128, 0)
            hBlank := DllCall("CreateCursor", "Ptr", 0, "Int", 0, "Int", 0
                , "Int", 32, "Int", 32
                , "Ptr", andMask, "Ptr", xorMask, "Ptr")
            cursors[id] := Map("default", hDefault, "blank", hBlank)
        }
    }

    switch cmd {
        case "Show": visible := true
        case "Hide": visible := false
        case "Toggle": visible := !visible
        default: return
    }

    for id, cur in cursors {
        hSet := DllCall("CopyImage", "Ptr", visible ? cur["default"] : cur["blank"]
            , "UInt", 2, "Int", 0, "Int", 0, "UInt", 0, "Ptr")
        DllCall("SetSystemCursor", "Ptr", hSet, "UInt", id)
    }
}