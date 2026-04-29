// test_gmail.qml — run with: quickshell -p test_gmail.qml
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    // Simulates what EmailService does internally
    property string accessToken: ""
    property string refreshToken: "PASTE_YOUR_REFRESH_TOKEN_HERE"

    IpcHandler {
        target: "gmail"
        function onTokenRefreshed(token: string, expiresIn: int) {
            console.log("[TEST] access_token received:", token.substring(0, 20) + "...")
            accessToken = token
            testApiCall()
        }
        function onAuthComplete(refresh: string, email: string) {
            console.log("[TEST] Auth complete! email:", email, "refresh:", refresh.substring(0, 10) + "...")
        }
    }

    Component.onCompleted: {
        console.log("[TEST] Starting token refresh...")
        refreshProc.running = true
    }

    Process {
        id: refreshProc
        command: ["python3",
            Qt.resolvedUrl("token_refresh.py").toString().replace("file://", ""),
            refreshToken
        ]
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    const data = JSON.parse(line)
                    console.log("[TEST] Token OK, expires in:", data.expires_in, "seconds")
                    accessToken = data.access_token
                    testApiCall()
                } catch(e) {
                    console.error("[TEST] Parse error:", line)
                }
            }
        }
        stderr: SplitParser {
            onRead: function(line) { console.error("[TEST] Script error:", line) }
        }
    }

    function testApiCall() {
        console.log("[TEST] Making API call...")
        const xhr = new XMLHttpRequest()
        xhr.open("GET", "https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=3&labelIds=INBOX")
        xhr.setRequestHeader("Authorization", "Bearer " + accessToken)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            console.log("[TEST] Status HTTP:", xhr.status)
            if (xhr.status === 200) {
                const data = JSON.parse(xhr.responseText)
                console.log("[TEST] Messages received:", data.messages?.length ?? 0)
                data.messages?.forEach((m, i) => console.log(`  [${i}] id: ${m.id}`))
                testLabels()
            } else {
                console.error("[TEST] API Error:", xhr.responseText)
            }
        }
        xhr.send()
    }

    function testLabels() {
        const xhr = new XMLHttpRequest()
        xhr.open("GET", "https://gmail.googleapis.com/gmail/v1/users/me/labels")
        xhr.setRequestHeader("Authorization", "Bearer " + accessToken)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) {
                const data = JSON.parse(xhr.responseText)
                const userLabels = data.labels.filter(l => l.type === "user")
                console.log("[TEST] User labels:", userLabels.map(l => l.name).join(", "))
                testSendDryRun()
            }
        }
        xhr.send()
    }

    function testSendDryRun() {
        // Tests the raw email build function without actually sending
        const raw = buildRawEmail("test@example.com", "Quickshell Gmail Test", "It works!")
        console.log("[TEST] Raw email (base64url):", raw.substring(0, 40) + "...")
        console.log("[TEST] ✅ All tests passed!")
    }

    function buildRawEmail(to, subject, body) {
        let raw = `To: ${to}\r\nSubject: ${subject}\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n${body}`
        return btoa(unescape(encodeURIComponent(raw)))
            .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
    }
}