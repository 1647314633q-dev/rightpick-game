# 🆕 合併版說明（大螢幕 Kiosk ＋ 手機掃碼玩）

- **大螢幕**：照舊用 `start-windows.bat`（或網址加 `?kiosk=1`）。放上 https 網址之後，主選單底部 QR 會自動變成「📱 排緊隊？掃碼用自己手機玩」。
- **手機**：遊客掃 QR → 用自己手機前鏡頭玩同一套 4 個遊戲（一隻手揸手機，另一隻手喺鏡頭前郁；黃大仙可以直接搖手機）。玩完個畫面俾職員睇就蓋印，唔會自動跳走，方便截圖。
- 手機玩一定要經 **https** 網址（例如 GitHub Pages），本機 localhost 只啱大螢幕。
- `CONFIG.playUrl`：想 QR 指去其他網址先填，留空會自動用目前網址。

---

# RightPick 職場遊樂場 — 展覽互動遊戲（Kiosk 版）

一個**大螢幕 + 一個 webcam**就玩得嘅 Career Fair 攤位遊戲。
玩家行埋嚟、舉手，就可以打爆職場地雷、求籤、二選一、扭蛋；玩完即場出一張**可以影相放 IG Story** 嘅結果卡。

- 4 個遊戲，每個 20–40 秒
- 手勢操作（MediaPipe 手部追蹤），唔需要玩家出手機或電腦
- 內置「打卡卡」＋ QR Code，玩完帶走
- 完全離線可用（手勢模型、QR 全部放喺 `assets/`）
- 工作人員設定台（按 `P`）：統計、鏡頭、靈敏度、匯出 CSV
- 隱私：鏡頭影像只留喺瀏覽器記憶體，**不錄影、不上傳**

---

## 1. 先答你個問題：唔好用「掃 QR → 大螢幕出現遊戲」

你提出嘅方案係：玩家掃顯示屏個 QR Code，然後大螢幕出遊戲畫面。技術上做得到，但**唔適合做主要入口**，原因好實際：

| 問題 | 影響 |
|---|---|
| 掃碼 → 開瀏覽器 → 載入頁面，每次多 5–15 秒 | 展覽每小時得 60 分鐘，條隊會塞死 |
| 手機冇電、冇數據、公司 Wi-Fi 唔穩、IG/微信內置瀏覽器 | 每次都可能有 10–20% 人卡住，要 staff 救 |
| 螢幕反光、QR 太細、玩家企錯位 | 掃唔到，直接放棄 |
| 個個低頭睇手機 | **攤位望落去好似冇人玩**，最致命 |
| 要玩家用手機鏡頭做手勢 | iOS Safari 權限／效能／過熱問題多 |
| 共用觸控螢幕 | 要不停抹，衛生觀感差 |

**圍觀人流係靠「見到前面嗰個人玩得好開心」**。如果所有人都係低頭撳手機，就冇人會停低。手勢遊戲最大價值就係「成個人郁、有聲、有爆炸、旁邊的人會笑」——呢個係實體攤位先做到嘅事。

所以建議嘅架構係：

```
大螢幕（TV） + webcam + 一部 mini PC / laptop（工作人員嘅，唔係玩家嘅）
        ↓
玩家行埋嚟，舉手就玩（20–40 秒）
        ↓
結果卡出場 → 玩家用手機影低 / 掃卡上 QR 帶走
        ↓
QR Code 嘅真正工作：帶走結果、事後去 RightPick、 IG 分享
```

**QR Code 唔係用嚟開始遊戲，係用嚟帶走結果。** 呢個版本已經做咗：

1. 每個結果卡都有自己嘅 QR（`#r=...`）——玩家掃一掃，手機直接打開同一張卡，可以截圖、分享。
2. 大螢幕下面有 RightPick 網站 QR，等排隊嘅人掃。
3. 如果部機冇上網（localhost），QR 會自動改為指向 RightPick 官網，唔會指去 localhost 得個桔。

> 唯一值得做「掃 QR → 大螢幕」嘅情況，係 **Jackbox 式雙人對戰**：手機做控制器、大螢幕做棋盤。呢個留返做 v2，而且要場地有穩定 Wi-Fi。

---

## 2. 硬件建議

### 方案 A（推薦）：電視 + USB webcam + mini PC

| 項目 | 建議 | 備註 |
|---|---|---|
| 螢幕 | 55"–65" 4K 電視 | 直放／橫放都得，橫放 16:9 最好 |
| 鏡頭 | Logitech C920 / C930e，或任何 1080p USB webcam | 唔好用超廣角魚眼，手會變形 |
| 電腦 | Intel N100 mini PC / 任何 i3 以上 laptop | Windows 10/11 + Chrome |
| 喇叭 | 電視內置或 2.1 喇叭 | 有聲先有人停 |
| 其他 | 腳架／電視掛架、膠紙（地下貼「企喺呢度」）、拖板 | |

設定：
- Webcam 放**電視頂部正中**，鏡頭微微向下傾。
- 玩家企喺鏡頭前 **1.5–2 米**，地下貼腳印。
- 鏡頭要見到玩家**上半身 + 舉高嘅手**。開場畫面會有虛線框同文字提示，工作人員可以即刻調。
- 光要**打向玩家塊面**，唔好淨係打向電視（背光會令手勢偵測變差）。

### 方案 B：觸控 Kiosk（一體機）
最穩定，但冇「動感」效果，圍觀性差一截。遊戲本身支援觸控（`?mouse=1`），一樣玩得。

### 方案 C：投影機
畫面大，但展覽場地通常好光，對比度差；鏡頭又要另外裝。唔建議。

---

## 3. 快速開始（Windows，5 分鐘）

1. 將成個 `rightpick-arcade` 資料夾 copy 去電腦（可以放 USB）。
2. 雙擊 **`start-windows.bat`**。
   - 會自動起一個本機伺服器（Python，冇 Python 就用 PowerShell）。
   - 會自動開 Chrome **Kiosk 全螢幕**，網址 `http://localhost:8080/?kiosk=1`。
   - 第一次可能會問鏡頭權限；啟動參數已經幫你自動允許。
3. 見到「行埋嚟，舉手就玩」→ 完成。
4. 離開：`Alt + F4`。
5. 想試玩／調鏡頭：雙擊 **`start-debug.bat`**（普通 Chrome 視窗，唔會鎖全螢幕）。

> **一定要經 `localhost` 開，唔好雙擊 `index.html`。**
> 瀏覽器只會喺 `https://` 或 `localhost` 之下開放鏡頭同 WebAssembly 模組；用 `file://` 開會載入唔到手勢模型。

### macOS / 其他電腦
喺資料夾入面開 terminal：

```bash
python3 server.py 8080
# 然後開 Chrome： http://localhost:8080/?kiosk=1
```

---

## 4. 現場流程（Run of Show）

| 時間 | 做咩 |
|---|---|
| 開場前 15 分鐘 | 開機 → 行 `start-windows.bat` → 等菜單出現 → 舉手試玩一局 → 檢查喇叭聲量 → 地下貼腳印 |
| 有人行過 | 工作人員講：「過嚟玩呀，舉手就玩，30 秒，免費！」（唔好叫佢掃 QR） |
| 玩家揀遊戲 | 手掌停喺卡上面 1 秒 |
| 玩完 | 結果卡出場 → 「影低張卡放 IG Story 呀」→ 蓋印 |
| 下一位 | 結果畫面 30 秒自動返主頁，或者玩家自己撳「主頁」 |

**每局時間**：擊碎爛工 20 秒、黃大仙約 25 秒、二選一約 30 秒、扭蛋約 20 秒。
**每小時吞吐量**：單一遊戲約 60–80 人；4 個遊戲任揀約 40–60 人。

工作人員快捷鍵（USB 鍵盤）：

| 鍵 | 功能 |
|---|---|
| `F` | 全螢幕 |
| `P` | 工作人員設定台（統計／鏡頭／靈敏度） |
| `1` `2` `3` `4` | 直接開四個遊戲 |
| `Esc` / `0` | 返主頁 |
| `M` | 切換手勢／滑鼠模式 |
| `S` | 顯示手部骨架（debug） |

---

## 5. 想改內容／難度

打開 `index.html`，最上面有一個 `CONFIG`：

```js
const CONFIG = {
  brand:'RightPick',
  webUrl:'https://rightpick.online/',   // QR 目標網址（改呢度）
  webLabel:'rightpick.online',          // 卡面顯示嘅網址
  shareBase:'',                         // 留空 = 自動用目前網址（見第 6 節）
  smashSeconds:20,      // 擊碎爛工秒數
  choiceRounds:3,       // 二選一題數
  choiceSeconds:5,      // 每題限時
  shakeTarget:2.6,      // 搖籤難度（越大越難）
  gachaTurns:2,         // 扭蛋要扭幾多圈
  goldRate:0.10,        // 金蛋機率
  resultTimeout:30,     // 結果畫面幾秒後返主頁
  idleSeconds:70,       // 遊戲中幾耐冇人返主頁
  minHandSize:0.075,    // 手掌最細尺寸（過濾背景路人）
  hitSpeed:0.55,        // 揮手命中速度
  prayDist:0.24,        // 合十判定距離
  mirror:true,          // 鏡像
  sound:true,
};
```

遊戲內容（職場地雷、籤文、二選一題目、職業卡、屬性）都喺下面 `MINES`、`FORTUNES`、`QUESTIONS`、`JOBS` 等陣列，直接改字就得。

**唔想改 code 嘅設定**：按 `P` 開工作人員台，可以即場調：
- 揮手速度（打唔中就調低）
- 手掌大小門檻（成日誤觸就調高）
- 結果停留秒數
- 鏡頭選擇、鏡像、音效
- 今日統計 + 匯出 CSV

---

## 6. 放上網（想要「逐人 QR 帶走張卡」就一定要）

本機版嘅 QR 只可以指向 RightPick 官網（因為手機連唔到 `localhost`）。
如果你想**每個玩家嘅 QR 都打開返佢自己嗰張卡**，就要將成個資料夾放上一個公開網址：

1. 將 `index.html` + `assets/` + `server.py` 上傳去 Netlify / Cloudflare Pages / GitHub Pages（拖放就得）。
2. 用嗰個網址開遊戲（例如 `https://arcade.rightpick.online/`）。
3. 完成。`shareBase` 留空會自動用 `location.origin + pathname`；QR 會變成
   `https://arcade.rightpick.online/#r=fortune;3;42`，手機打開就係同一張卡。
4. 如果遊戲機都係用同一個公開網址開，記得 WiFi 要穩定；唔穩定就用本機版，`shareBase` 手動填公開網址。

```js
javascript
// 例子：本機跑遊戲，但 QR 指向公開網址
shareBase: 'https://arcade.rightpick.online/'
```

---

## 7. 常見問題

**Q：鏡頭開唔到？**
- 一定要 `http://localhost` 或 `https://`，唔好用 `file://`。
- 睇下係咪有其他程式（Zoom / Teams / OBS）佔用鏡頭。
- Windows 設定 → 隱私 → 相機 → 允許桌面應用程式。
- 遊戲會自動重試；USB 拔插後會自己 reconnect。

**Q：手勢唔準／打唔中？**
- 光線不足係第一位。加一盞燈打向玩家。
- 玩家企太遠（手太細）→ 行近啲，或調低「手掌大小」門檻。
- 背景太多人走來走去 → 調高「手掌大小」門檻，只認最近嗰個人。
- 玩家太矮／太高 → 調低或調高 webcam 角度；遊戲開始前 3 秒熱身會自動校準可觸及範圍。

**Q：成日誤觸／自己跳去玩？**
- 調高「手掌大小」門檻（例如 0.09–0.11）。
- 鏡頭唔好對住走廊人潮，對住攤位前面嘅空地。

**Q：載入好慢？**
- 第一次要載 7.6MB 手勢模型 + 9.4MB wasm，本機大约 1–3 秒。
- 如果 `assets/` 唔見咗，會自動 fallback 去 CDN，需要上網。

**Q：冇網絡玩唔玩到？**
- 玩到。模型、QR、全部字體都喺本機。只有 fallback CDN 先需要網。

**Q：玩家嘅影像會唔會儲存？**
- 唔會。影像只係經 `getUserMedia` 入 canvas 做即時分析，冇錄影、冇上傳、冇寫入硬碟。
- 建議喺攤位加一張「本遊戲使用鏡頭偵測手勢，不會錄影」嘅告示（開場畫面已有字）。

**Q：可以幾個人一齊玩？**
- 而家設計係一次一位（手勢追蹤同時認 2 隻手，即係一個人嘅雙手）。
- 雙人對戰係 v2 嘅事（要分左右半場 + 分數比較）。

**Q：點解結果畫面自己跳走？**
- 30 秒自動返主頁，等下一位玩家。`P` → 「結果停留」可以改。

---

## 8. 技術備註

- 手勢：MediaPipe Tasks Vision `HandLandmarker`（0.10.14），21 個手部節點，同時追 2 隻手，約 30fps。
- 只用 palm centre + 速度 + 停留時間做判定，冇用 ML 分類器，所以 CPU 佔用低。
- 擊碎爛工開始前有 **3 秒熱身校準**：記錄玩家雙手可觸及範圍，再喺範圍內出 target，避免「target 出喺天花」。
- 背景路人過濾：手掌尺寸 < `minHandSize × 畫面高度` 就忽略。
- 統計存 `localStorage`（每日 reset），可匯出 CSV。
- 冇後端、冇 cookie、冇 tracking。

---

## 9. 檔案結構

```
rightpick-arcade/
├─ index.html              ← 成個遊戲（HTML + CSS + JS 一個檔）
├─ server.py               ← 本機靜態伺服器（Python 3）
├─ server.ps1              ← 後備伺服器（冇 Python 時用）
├─ start-windows.bat       ← 展覽用：一鍵起 server + Chrome Kiosk
├─ start-debug.bat         ← 設定用：普通 Chrome 視窗
├─ assets/
│  ├─ qrcode.js            ← QR Code 產生器
│  └─ mediapipe/
│     ├─ vision_bundle.js  ← MediaPipe 手勢 library
│     ├─ hand_landmarker.task
│     └─ wasm/…
├─ shots/                  ← 畫面預覽圖（俾你睇設計）
└─ README.md
```

---

## 10. 已測試

- ✅ Node `--check` 語法檢查（module 65k 字元）
- ✅ jsdom 煙霧測試：4 個遊戲啟動、8 張地雷卡、熱身校準、target 生成、4 款結果卡、QR 生成、手機打卡頁（4 種卡）
- ✅ Chrome headless 截圖：1920×1080 各畫面、手機 9:16 打卡頁
- ✅ Chrome 假鏡頭 E2E：`?kiosk=1` 自動開鏡頭 → 本機 MediaPipe 模型載入 → `mode=camera`、`tracker` 就緒、自動入菜單（見 `shots/10-kiosk-camera.png`）
- ✅ PowerShell 後備伺服器實測（正確 MIME、大檔 7.8MB 正常）
- ⚠️ 未測試：真實 webcam 手勢表現（要喺現場機器試）、iOS Safari `navigator.share`、連續運行 8 小時

**展覽前一定要做**：喺真實場地光線下，用真實玩家身高試玩 10 局，再微調 `minHandSize` 同 `hitSpeed`。
