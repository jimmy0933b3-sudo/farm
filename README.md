# 動物探險島 Animal Adventure Island

適合 3～5 歲孩子的繁體中文、離線 Android 動物探索與簡易照護遊戲。

## 首版已實作

- 農場和森林，各 6 種動物，共 12 隻由 Godot 程式繪製的原創向量造型
- 動物觸碰、開心表情、各種離線合成音效
- 12 個關卡，包含聲音辨識、食物配對、棲地配對
- 六隻可照護動物的餵食、洗澡、玩耍、休息
- 圖鑑剪影與收集功能
- 本地 JSON 版本化存檔、備份、損壞存檔安全處理
- 家長簡單算術門檻與音效設定
- Android 橫向畫面與 GitHub Actions APK 自動匯出

## 尚待後續改進（誠實揭露）

- 目前的音效是離線合成音符，並非真實動物錄音；中文語音朗讀尚未製作。
- 美術為程式直接繪製的 Q 版動物草圖，未含完整逐格動畫。
- 三種關卡目前使用點選操作，未提供拖曳食物動畫。
- 背景音樂、家長使用時間提醒、裝飾玩法仍未實作。
- 此 Repository 尚未提供正式 release 簽章密鑰，CI 產出的 debug APK 僅供安裝測試，不可視為具固定簽章的正式上架版；不同 runner 產生的測試金鑰可能不同。

## 開發

使用 Godot **4.5.2** 開啟根目錄的 `project.godot`，執行主場景。

從專案根目錄執行：

```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/validate.gd
```

`.github/workflows/android.yml` 在每次推送 main 時自動檢查資料並嘗試匯出可安裝 debug APK。下載路徑：GitHub → Actions → Android APK → 選擇成功執行 → Artifacts。

目前以 Android Debug 簽章方便先行測試。若需要**更新安裝不重灌**，必須另外配置受保護的固定正式金鑰與對應 release export；請不要將正式 keystore 提交到公開 Repository。

## 資料與隱私

無登入、無廣告、無網路請求、無第三方追蹤。遊戲狀態存放於裝置的 `user://animal_island_save.json`。

## 授權

原創程式繪製動物、場景與合成音效，沒有採用未授權第三方圖片或錄音。本專案未設定對外開源授權，保留相關權利。

## V0.2 Voice-first improvements

- Real CC0 recorded animal calls are bundled offline for cow, pig, sheep, rooster, duck, horse, owl. No more pitch-shifted electronic animal calls.
- Wild animals with no verified sound (rabbit, squirrel, fox, deer, bear) are introduced with Mandarin voice rather than fabricated animal sounds.
- Food, habitats and care actions have original vector picture cards so pre-readers can play without reading.
- Spoken Chinese guidance uses **Godot native TTS** with the Android device's installed Mandarin voices. For fully offline guidance, install a **Traditional Chinese offline speech voice** in Android text-to-speech settings. When no Chinese speech engine is installed, large picture buttons remain available; speech might be unavailable until set up.

### Audio recording credits (CC0 1.0)

Audio re-used from Freesound as independently licensed CC0 recordings, transferred via the public WilhelmSFX sample mirror. Sources:

- Cow: [Bird_man / Moo.wav](https://freesound.org/people/Bird_man/sounds/275154/)
- Pig: [qubodup / Pig Oink](https://freesound.org/people/qubodup/sounds/442906/)
- Sheep: [edschaefer / Sheeplings](https://freesound.org/people/edschaefer/sounds/380042/)
- Rooster: [BenjaminNelan / Rooster Crow 1](https://freesound.org/people/BenjaminNelan/sounds/435508/)
- Duck: [D4XX / Ducks](https://freesound.org/people/D4XX/sounds/607226/)
- Horse: [shadoWisp / horse neigh shortened](https://freesound.org/people/shadoWisp/sounds/269571/)
- Owl: [Gerent / owl_hooting](https://freesound.org/people/Gerent/sounds/558397/)

Every source has its own CC0 license; see linked Freesound listing.

## V0.3 Interactive petting and expressive care

- In the animal profile, drag a finger over the animal to control a visible hand. A continuous stroke, not a button click, earns a happy face and floating hearts. The petting button demonstrates the gesture.
- Animal Care shows distinct animations for feeding (moving food bowl and chewing), washing (bubbles), playing (bouncing ball), resting (sleeping eyes and blanket).
- Each care action saves the changed stat and animates its progress bar on the same scene. Entry narration plays only when entering Animal Home; actions use short action-specific responses.
- The interaction smoke test simulates finger strokes and checks all four care actions without recreating the page or repeating the introduction.

## V0.4 森林尋寶

- 森林樂園新增「森林尋寶：找動物」入口。
- 6 種森林動物隨機躲在樹洞、花叢、石頭、木頭、樹枝及草叢。
- 大幅可點擊的隱藏地點、目標動物圖片、中文語音提示。
- 找錯不扣分，連續兩次找錯，正確躲藏處會亮出金色提示圈，也可按提示按鈕。
- 找對後顯示動物和動畫，解鎖圖鑑並把發現紀錄存到 forest_found；找到全部六隻可重玩，位置重新洗牌。
- 音效與語音遵守原有設定，沒有計時、強制扣分與付費。

## 大森林探索（首頁獨立模式）

- 首頁新增 **大森林探索** 圖片 icon，可直接進入完整模式，不用先進森林樂園。
- 長達 2920px 的 **橫向大森林**，有花叢、樹洞、岩石步道、溪流木橋、倒木與樹枝區域，不是六宮格靜態畫面。
- 用手指拖曳（或下方左右大按鈕）移動地圖，點藏身位置尋找兔子、松鼠、狐狸、鹿、熊、貓頭鷹。
- 目標圖片和繁體中文 TTS 指引固定顯示；找錯不扣分，兩次錯誤給金色光圈並平移到附近。
- 動物揭曉有彈出動畫。發現紀錄同時寫入 `forest_found` 與圖鑑；中斷時保存當回合藏點和已找到的進度，重開後可以接續。
- 完成六隻會顯示完成畫面與「再玩一次／回首頁／回森林樂園」，重玩重新洗牌，紀錄完成次數。
- 可完全離線遊玩，遵守既有語音與減少動態效果設定。

由 `ForestPanMap.gd` 負責地圖繪製、捲動與手勢，`ForestDiscovery.gd` 負責關卡、提示與發現流程，`SaveData.gd` 負責延續存檔。

## 2026-10-23 橫向排版與 4 隻新動物

- 修正首頁卡片下方副標籤重疊；首頁 icon 與標題都留在卡片內，不再溢位。
- 修正大森林白色 Button 背景遮住場景：躲藏物改為純 Control 由地圖統一處理觸控。
- 縮小森林 HUD 與底部操作列最低高度，針對平板橫向解析度節省空間。
- 森林增加 **刺蝟、浣熊、野豬、猴子**，森林探索擴大至 10 隻；總動物 16 隻，各自有原創矢量插畫、食物或棲地關卡和中文語音介紹。沒有正確錄音的動物不偽造叫聲。
- 地圖延長到 4720px、藏點增加至 10 個。舊資料保留在圖鑑與發現紀錄中。

## 固定簽章與可直接升級的 Android APK

自 2026-10-23 起，GitHub Actions 在 `main` push 或手動執行時，讀取 Repository secrets：`KEYSTORE_BASE64`、`KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD`。工作流程會在 runner 的臨時目錄解碼 keystore，經過憑證與 alias 驗證後，以 **同一組金鑰簽署 release APK**；沒有四個 secrets 時會明確失敗，絕不退回每次重新產生的 debug key。Pull request 只跑測試，不提供 secrets 也不產生已簽章 APK。

Godot 4.5 使用一組憑證密碼，CI 將輸入 keystore 的不同 `KEY_PASSWORD` 正規化成臨時 PKCS12，不變更原私鑰或憑證。Android package ID 維持 `com.jimmy0933.animalisland`，CI 以 GitHub Actions run number 自動遞增 versionCode，APK 附上 `SIGNING-INFO.txt` 記錄公開憑證 SHA-256 指紋並確認與輸入金鑰完全相同。

**第一次改用固定簽章要注意：**先前 CI 使用臨時 debug key。如果手機上安裝的是舊 debug APK，憑證不同時 Android 無法直接覆蓋安裝；請先備份舊版遊戲資料（若沒有備份功能則無法保證保留），之後才移除舊版並安裝新的固定簽章 APK。往後用**同一份 keystore、相同 package ID、較高 versionCode** 才能正常更新，不應換掉這四個 secrets 所代表的私鑰。請妥善在 GitHub 以外保留加密金鑰備份。
