// U4BIA.swift — U₄-BI-A Multi-Calendar Menu Bar App
// macOS status bar app showing all 27 calendars in main window,
// 1-3 selected calendars in menu bar popover, background-resident.
// Requires macOS 14+. Build via Xcode or: swift build && swift run

import SwiftUI
import AppKit
import Combine

// MARK: - Localization

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case en = "English"
    case ja = "日本語"
    case fr = "Français"
    var id: String { rawValue }
}

struct L10n {
    let lang: AppLanguage
    var appTitle: String { "U\u{2084}-BI-A" }
    var appSubtitle: String {
        switch lang { case .en: return "MULTI-CALENDAR"; case .ja: return "多暦表示"; case .fr: return "MULTI-CALENDRIER" }
    }
    var allCalendars: String {
        switch lang { case .en: return "All Calendars"; case .ja: return "全暦法"; case .fr: return "Tous les calendriers" }
    }
    var settings: String {
        switch lang { case .en: return "Settings"; case .ja: return "設定"; case .fr: return "Réglages" }
    }
    var menuBarSelection: String {
        switch lang { case .en: return "Menu Bar Calendars"; case .ja: return "メニューバー表示暦"; case .fr: return "Calendriers barre de menus" }
    }
    var todaysFestivals: String {
        switch lang { case .en: return "Today's Festivals"; case .ja: return "今日の祝祭"; case .fr: return "Fêtes du jour" }
    }
    var noFestivals: String {
        switch lang { case .en: return "No festivals today"; case .ja: return "今日の祝祭はありません"; case .fr: return "Aucune fête aujourd'hui" }
    }
    var openWindow: String {
        switch lang { case .en: return "Open Full View"; case .ja: return "全暦ウィンドウを開く"; case .fr: return "Ouvrir la vue complète" }
    }
    var quit: String {
        switch lang { case .en: return "Quit"; case .ja: return "終了"; case .fr: return "Quitter" }
    }
    var background: String {
        switch lang { case .en: return "Background"; case .ja: return "背景"; case .fr: return "Arrière-plan" }
    }
    var language: String {
        switch lang { case .en: return "Language"; case .ja: return "言語"; case .fr: return "Langue" }
    }
}

// ============================================================================
// CALENDAR DEFINITIONS, ENGINE, AND FESTIVAL DATA
// (preserved from previous version — 858 lines of computation logic)
// ============================================================================

// MARK: - Calendar Definitions

enum CalendarSystem: String, CaseIterable, Identifiable, Codable {
    case gregorian, julian, chinese, hebrew, islamic, persian, buddhist, japanese, roc, julianDay
    case coptic, ethiopic, indian, iso8601, pawukon, frenchRepublican, internationalFixed
    case positivist, mayaLongCount, aztecTonalpohualli, aztecXiuhpohualli, tibetan
    case sumerianSexagesimal, egyptianHours, chineseKe, indianGhati, decimalTime

    var id: String { rawValue }

    func displayName(_ lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.gregorian, .en): return "Gregorian Calendar"
        case (.gregorian, .ja): return "グレゴリオ暦"
        case (.gregorian, .fr): return "Calendrier grégorien"
        case (.julian, .en): return "Julian Calendar"
        case (.julian, .ja): return "ユリウス暦"
        case (.julian, .fr): return "Calendrier julien"
        case (.chinese, .en): return "Chinese Lunar Calendar"
        case (.chinese, .ja): return "旧暦（太陰太陽暦）"
        case (.chinese, .fr): return "Calendrier chinois"
        case (.hebrew, .en): return "Hebrew Calendar"
        case (.hebrew, .ja): return "ヘブライ暦"
        case (.hebrew, .fr): return "Calendrier hébraïque"
        case (.islamic, .en): return "Islamic Hijri Calendar"
        case (.islamic, .ja): return "ヒジュラ暦"
        case (.islamic, .fr): return "Calendrier islamique (Hégire)"
        case (.persian, .en): return "Solar Hijri (Persian)"
        case (.persian, .ja): return "ヒジュラ太陽暦（イラン暦）"
        case (.persian, .fr): return "Calendrier persan (Hégirien solaire)"
        case (.buddhist, .en): return "Buddhist Calendar"
        case (.buddhist, .ja): return "仏暦"
        case (.buddhist, .fr): return "Calendrier bouddhiste"
        case (.japanese, .en): return "Japanese Calendar"
        case (.japanese, .ja): return "和暦"
        case (.japanese, .fr): return "Calendrier japonais"
        case (.roc, .en): return "ROC Calendar (Minguo)"
        case (.roc, .ja): return "民国暦"
        case (.roc, .fr): return "Calendrier minguo"
        case (.julianDay, .en): return "Julian Day Number"
        case (.julianDay, .ja): return "ユリウス通日"
        case (.julianDay, .fr): return "Jour julien"
        case (.coptic, .en): return "Coptic Calendar"
        case (.coptic, .ja): return "コプト暦"
        case (.coptic, .fr): return "Calendrier copte"
        case (.ethiopic, .en): return "Ethiopic Calendar"
        case (.ethiopic, .ja): return "エチオピア暦"
        case (.ethiopic, .fr): return "Calendrier éthiopien"
        case (.indian, .en): return "Indian National Calendar"
        case (.indian, .ja): return "インド国定暦"
        case (.indian, .fr): return "Calendrier national indien"
        case (.iso8601, .en): return "ISO 8601"
        case (.iso8601, .ja): return "ISO 8601"
        case (.iso8601, .fr): return "ISO 8601"
        case (.pawukon, .en): return "Pawukon Calendar (Bali)"
        case (.pawukon, .ja): return "パウコン暦（バリ島）"
        case (.pawukon, .fr): return "Calendrier Pawukon (Bali)"
        case (.frenchRepublican, .en): return "French Republican Calendar"
        case (.frenchRepublican, .ja): return "フランス共和暦"
        case (.frenchRepublican, .fr): return "Calendrier républicain"
        case (.internationalFixed, .en): return "International Fixed Calendar"
        case (.internationalFixed, .ja): return "国際固定暦"
        case (.internationalFixed, .fr): return "Calendrier fixe international"
        case (.positivist, .en): return "Positivist Calendar"
        case (.positivist, .ja): return "実証主義暦"
        case (.positivist, .fr): return "Calendrier positiviste"
        case (.mayaLongCount, .en): return "Maya Long Count"
        case (.mayaLongCount, .ja): return "マヤ長期暦"
        case (.mayaLongCount, .fr): return "Compte long maya"
        case (.aztecTonalpohualli, .en): return "Aztec Tonalpohualli (260-day)"
        case (.aztecTonalpohualli, .ja): return "アステカ暦トナルポワリ（260日）"
        case (.aztecTonalpohualli, .fr): return "Tonalpohualli aztèque (260 jours)"
        case (.aztecXiuhpohualli, .en): return "Aztec Xiuhpohualli (365-day)"
        case (.aztecXiuhpohualli, .ja): return "アステカ太陽暦シウポワリ（365日）"
        case (.aztecXiuhpohualli, .fr): return "Xiuhpohualli aztèque (365 jours)"
        case (.tibetan, .en): return "Tibetan Calendar (Phukpa)"
        case (.tibetan, .ja): return "チベット暦（プクパ）"
        case (.tibetan, .fr): return "Calendrier tibétain (Phukpa)"
        case (.sumerianSexagesimal, .en): return "Sumerian Sexagesimal Time"
        case (.sumerianSexagesimal, .ja): return "シュメール六十進法時間"
        case (.sumerianSexagesimal, .fr): return "Temps sexagésimal sumérien"
        case (.egyptianHours, .en): return "Egyptian Seasonal Hours"
        case (.egyptianHours, .ja): return "古代エジプト不定時法"
        case (.egyptianHours, .fr): return "Heures saisonnières égyptiennes"
        case (.chineseKe, .en): return "Chinese Ke System"
        case (.chineseKe, .ja): return "漏刻制"
        case (.chineseKe, .fr): return "Système chinois des Ke"
        case (.indianGhati, .en): return "Indian Ghati (Surya Siddhanta)"
        case (.indianGhati, .ja): return "インド・ガティ（スーリヤ・シッダーンタ）"
        case (.indianGhati, .fr): return "Ghati indien (Surya Siddhanta)"
        case (.decimalTime, .en): return "French Decimal Time"
        case (.decimalTime, .ja): return "フランス十進法時間"
        case (.decimalTime, .fr): return "Temps décimal français"
        }
    }
}

// MARK: - Calendar Result & Engine

struct CalendarResult {
    let title: String; let dateLine: String; let timeLine: String; let extraInfo: String
}

class CalendarEngine {
    static let shared = CalendarEngine()

    func compute(_ sys: CalendarSystem, date: Date, lang: AppLanguage) -> CalendarResult {
        let t = sys.displayName(lang)
        switch sys {
        case .gregorian: return gregorian(date, lang, t)
        case .julian: return julian(date, lang, t)
        case .chinese: return chinese(date, lang, t)
        case .hebrew: return hebrew(date, lang, t)
        case .islamic: return islamic(date, lang, t)
        case .persian: return persian(date, lang, t)
        case .buddhist: return buddhist(date, lang, t)
        case .japanese: return japanese(date, lang, t)
        case .roc: return roc(date, lang, t)
        case .julianDay: return julianDay(date, lang, t)
        case .coptic: return coptic(date, lang, t)
        case .ethiopic: return ethiopic(date, lang, t)
        case .indian: return indian(date, lang, t)
        case .iso8601: return iso8601(date, lang, t)
        case .pawukon: return pawukon(date, lang, t)
        case .frenchRepublican: return frRepublican(date, lang, t)
        case .internationalFixed: return intlFixed(date, lang, t)
        case .positivist: return positivist(date, lang, t)
        case .mayaLongCount: return maya(date, lang, t)
        case .aztecTonalpohualli: return aztecTonal(date, lang, t)
        case .aztecXiuhpohualli: return aztecXiuh(date, lang, t)
        case .tibetan: return tibetan(date, lang, t)
        case .sumerianSexagesimal: return sumerian(date, lang, t)
        case .egyptianHours: return egyptian(date, lang, t)
        case .chineseKe: return ke(date, lang, t)
        case .indianGhati: return ghati(date, lang, t)
        case .decimalTime: return decimal(date, lang, t)
        }
    }

    // Helpers
    private func cal(_ id: Calendar.Identifier) -> Calendar { var c = Calendar(identifier: id); c.timeZone = .current; return c }
    private func gc(_ d: Date) -> DateComponents { cal(.gregorian).dateComponents([.era,.year,.month,.day,.hour,.minute,.second,.weekday], from: d) }
    private func ts(_ h: Int, _ m: Int, _ s: Int) -> String { String(format: "%02d:%02d:%02d", h, m, s) }
    private func jdn(_ d: Date) -> Double { d.timeIntervalSince1970 / 86400.0 + 2440587.5 }
    private func dayFrac(_ d: Date) -> Double { let c = gc(d); return (Double(c.hour!)*3600+Double(c.minute!)*60+Double(c.second!))/86400.0 }

    private let enM = ["","January","February","March","April","May","June","July","August","September","October","November","December"]
    private let jaM = ["","1月","2月","3月","4月","5月","6月","7月","8月","9月","10月","11月","12月"]
    private let frM = ["","janvier","février","mars","avril","mai","juin","juillet","août","septembre","octobre","novembre","décembre"]
    private func mn(_ m: Int, _ l: AppLanguage) -> String {
        guard m>=1 && m<=12 else { return "\(m)" }
        switch l {
        case .en: return enM[m]
        case .ja: return jaM[m]
        case .fr: return frM[m]
        }
    }

    private let enW = ["","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    private let jaW = ["","日曜日","月曜日","火曜日","水曜日","木曜日","金曜日","土曜日"]
    private let frW = ["","dimanche","lundi","mardi","mercredi","jeudi","vendredi","samedi"]
    private func wn(_ w: Int, _ l: AppLanguage) -> String {
        guard w>=1 && w<=7 else { return "\(w)" }
        switch l {
        case .en: return enW[w]
        case .ja: return jaW[w]
        case .fr: return frW[w]
        }
    }

    private func info3(_ en: String, _ ja: String, _ fr: String, _ l: AppLanguage) -> String {
        switch l { case .en: return en; case .ja: return ja; case .fr: return fr }
    }

    // MARK: Calendar implementations

    private func gregorian(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = gc(d)
        return CalendarResult(title: t,
            dateLine: "\(wn(c.weekday!, l)), \(mn(c.month!, l)) \(c.day!), \(c.year!)",
            timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("Solar · 365/366 days · Epoch: 1 AD", "太陽暦 · 365/366日 · 紀元: 西暦1年", "Solaire · 365/366 jours · Époque : 1 ap. J.-C.", l))
    }

    private func julian(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        // JDN-based Gregorian-to-Julian conversion (valid for any century)
        let j = Int(floor(jdn(d) + 0.5))
        // JDN → Julian date (algorithm from Meeus, Astronomical Algorithms)
        let c = j + 32082
        let dd = (4*c + 3) / 1461
        let ee = c - (1461*dd / 4)
        let mm = (5*ee + 2) / 153
        let jDay = ee - (153*mm + 2) / 5 + 1
        let jMonth = mm + 3 - 12 * (mm / 10)
        let jYear = dd - 4800 + mm / 10
        // Compute Gregorian-Julian offset dynamically
        let o = gc(d)
        let gY = o.year!; let gC = gY / 100
        let diffDays = gC - gC / 4 - 2  // standard century-based offset formula
        return CalendarResult(title: t, dateLine: "\(mn(jMonth, l)) \(jDay), \(jYear)",
            timeLine: ts(o.hour!, o.minute!, o.second!),
            extraInfo: info3("\(diffDays) days behind Gregorian · Leap every 4 yrs · 45 BC",
                "グレゴリオ暦より\(diffDays)日遅れ · 4年毎に閏年 · 前45年",
                "\(diffDays) jours de retard · Bissextile tous les 4 ans · 45 av. J.-C.", l))
    }

    private func chinese(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.chinese).dateComponents([.year,.month,.day,.isLeapMonth], from: d)
        let y=c.year!; let mo=c.month!; let dy=c.day!; let lp: Bool = c.isLeapMonth == true
        let idx=((y-1)%60+60)%60
        let stems=["Jia","Yi","Bing","Ding","Wu","Ji","Geng","Xin","Ren","Gui"]
        let branches=["Zi","Chou","Yin","Mao","Chen","Si","Wu","Wei","Shen","You","Xu","Hai"]
        let anEN=["Rat","Ox","Tiger","Rabbit","Dragon","Snake","Horse","Goat","Monkey","Rooster","Dog","Pig"]
        let anJA=["子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"]
        let anFR=["Rat","Bœuf","Tigre","Lapin","Dragon","Serpent","Cheval","Chèvre","Singe","Coq","Chien","Cochon"]
        let an: String; switch l { case .en: an=anEN[idx%12]; case .ja: an=anJA[idx%12]; case .fr: an=anFR[idx%12] }
        let lpS: String; switch l { case .en: lpS=lp ? "Leap ":""; case .ja: lpS=lp ? "閏":""; case .fr: lpS=lp ? "Intercal. ":"" }
        let o = gc(d)
        return CalendarResult(title: t,
            dateLine: "\(stems[idx%10])-\(branches[idx%12]) (\(an)) · \(lpS)Month \(mo), Day \(dy)",
            timeLine: ts(o.hour!, o.minute!, o.second!),
            extraInfo: info3("Lunisolar · 60-year cycle · 24 solar terms", "太陰太陽暦 · 60年周期 · 二十四節気", "Lunisolaire · Cycle de 60 ans · 24 termes solaires", l))
    }

    private func hebrew(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.hebrew).dateComponents([.year,.month,.day,.hour,.minute,.second], from: d)
        let ms=["","Tishrei","Cheshvan","Kislev","Tevet","Shevat","Adar","Adar II","Nisan","Iyar","Sivan","Tammuz","Av","Elul"]
        let m=(c.month!>=1&&c.month!<=13) ? ms[c.month!] : "\(c.month!)"
        return CalendarResult(title: t, dateLine: "\(c.day!) \(m) \(c.year!)", timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("Lunisolar · 19-yr Metonic cycle · Epoch: 3761 BC · Day from sunset",
                "太陰太陽暦 · 19年メトン周期 · 紀元前3761年 · 日没開始",
                "Lunisolaire · Cycle métonique 19 ans · 3761 av. J.-C. · Jour dès le coucher", l))
    }

    private func islamic(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.islamicUmmAlQura).dateComponents([.year,.month,.day,.hour,.minute,.second], from: d)
        let ms=["","Muharram","Safar","Rabi' al-Awwal","Rabi' al-Thani","Jumada al-Ula","Jumada al-Thani","Rajab","Sha'ban","Ramadan","Shawwal","Dhu al-Qi'dah","Dhu al-Hijjah"]
        let m=(c.month!>=1&&c.month!<=12) ? ms[c.month!] : "\(c.month!)"
        return CalendarResult(title: t, dateLine: "\(c.day!) \(m) \(c.year!) AH", timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("Pure lunar · 354-355 d/yr · Drifts ~10-11 d · Epoch: 622 (Hijra)",
                "純太陰暦 · 年354-355日 · 毎年約10-11日ずれ · ヒジュラ622年",
                "Lunaire pur · 354-355 j/an · Dérive ~10-11 j · Hégire 622", l))
    }

    private func persian(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.persian).dateComponents([.year,.month,.day,.hour,.minute,.second], from: d)
        let ms=["","Farvardin","Ordibehesht","Khordad","Tir","Mordad","Shahrivar","Mehr","Aban","Azar","Dey","Bahman","Esfand"]
        let m=(c.month!>=1&&c.month!<=12) ? ms[c.month!] : "\(c.month!)"
        return CalendarResult(title: t, dateLine: "\(c.day!) \(m) \(c.year!) SH", timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("Solar · Starts at Nowruz (vernal equinox) · Astronomically precise",
                "太陽暦 · ノウルーズ（春分）開始 · 天文学的に精確",
                "Solaire · Débute à Norouz (équinoxe) · Astronomiquement précis", l))
    }

    private func buddhist(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.buddhist).dateComponents([.year,.month,.day,.hour,.minute,.second], from: d)
        return CalendarResult(title: t, dateLine: "\(mn(c.month!, l)) \(c.day!), \(c.year!) BE",
            timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("Gregorian + 543 yrs · Epoch: Buddha's parinirvana",
                "グレゴリオ暦+543年 · 釈迦入滅紀元", "Grégorien + 543 ans · Parinirvana du Bouddha", l))
    }

    private func japanese(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.japanese).dateComponents([.era,.year,.month,.day,.hour,.minute,.second], from: d)
        let era: String
        switch c.era! {
        case 236: era = l == .ja ? "令和" : "Reiwa"
        case 235: era = l == .ja ? "平成" : "Heisei"
        case 234: era = l == .ja ? "昭和" : "Shōwa"
        case 233: era = l == .ja ? "大正" : "Taishō"
        case 232: era = l == .ja ? "明治" : "Meiji"
        default: era = "Era \(c.era!)"
        }
        let dl = l == .ja ? "\(era)\(c.year!)年\(c.month!)月\(c.day!)日" : "\(era) \(c.year!), \(mn(c.month!, l)) \(c.day!)"
        return CalendarResult(title: t, dateLine: dl, timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("Gregorian months/days · Imperial era years",
                "月日はグレゴリオ暦同一 · 天皇元号紀年",
                "Mois/jours grégoriens · Ères impériales", l))
    }

    private func roc(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.republicOfChina).dateComponents([.year,.month,.day,.hour,.minute,.second], from: d)
        let dl: String
        switch l {
        case .ja: dl = "民国\(c.year!)年\(c.month!)月\(c.day!)日"
        case .en: dl = "Year \(c.year!), \(mn(c.month!, l)) \(c.day!)"
        case .fr: dl = "An \(c.year!), \(c.day!) \(mn(c.month!, l))"
        }
        return CalendarResult(title: t, dateLine: dl, timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("Gregorian months/days · Year 1 = 1912 AD",
                "月日はグレゴリオ暦 · 元年=西暦1912年",
                "Mois/jours grégoriens · An 1 = 1912", l))
    }

    private func julianDay(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let j = jdn(d); let mjd = j - 2400000.5
        return CalendarResult(title: t, dateLine: String(format: "JD %.6f", j), timeLine: String(format: "MJD %.6f", mjd),
            extraInfo: info3("Continuous count from 4713 BC Jan 1 noon · No months/years",
                "前4713年1月1日正午からの連続日数 · 月年なし",
                "Décompte continu depuis 4713 av. J.-C. · Sans mois ni années", l))
    }

    private func coptic(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.coptic).dateComponents([.year,.month,.day,.hour,.minute,.second], from: d)
        let ms=["","Thout","Paopi","Hathor","Koiak","Tobi","Meshir","Paremhat","Parmouti","Pashons","Paoni","Epip","Mesori","Nasie"]
        let m=(c.month!>=1&&c.month!<=13) ? ms[c.month!] : "\(c.month!)"
        return CalendarResult(title: t, dateLine: "\(c.day!) \(m) \(c.year!) AM", timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("12×30 d + 5-6 d month · Epoch: 284 AD (Era of Martyrs)",
                "12×30日+5-6日の月 · 紀元284年（殉教者紀元）",
                "12×30 j + mois 5-6 j · Époque : 284 (Ère des Martyrs)", l))
    }

    private func ethiopic(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.ethiopicAmeteMihret).dateComponents([.year,.month,.day,.hour,.minute,.second], from: d)
        let ms=["","Mäskäräm","Ṭəqəmt","Ḫədar","Taḫśaś","Ṭərr","Yäkatit","Mägabit","Miyazya","Gənbot","Säne","Ḥamle","Nähase","Ṗagume"]
        let m=(c.month!>=1&&c.month!<=13) ? ms[c.month!] : "\(c.month!)"
        return CalendarResult(title: t, dateLine: "\(c.day!) \(m) \(c.year!)", timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("13 months · ~7-8 yrs behind Gregorian · New Year: Sept 11",
                "13ヶ月 · グレゴリオ暦より約7-8年遅れ · 新年: 9月11日",
                "13 mois · ~7-8 ans de retard · Nouvel An : 11 sept.", l))
    }

    private func indian(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.indian).dateComponents([.year,.month,.day,.hour,.minute,.second], from: d)
        let ms=["","Chaitra","Vaishakha","Jyeshtha","Ashadha","Shravana","Bhadra","Ashwin","Kartika","Agrahayana","Pausha","Magha","Phalguna"]
        let m=(c.month!>=1&&c.month!<=12) ? ms[c.month!] : "\(c.month!)"
        return CalendarResult(title: t, dateLine: "\(c.day!) \(m) \(c.year!) Saka", timeLine: ts(c.hour!, c.minute!, c.second!),
            extraInfo: info3("Solar · Saka Era · Official civil calendar of India",
                "太陽暦 · サカ紀元 · インド公式市民暦",
                "Solaire · Ère Saka · Calendrier civil de l'Inde", l))
    }

    private func iso8601(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let c = cal(.iso8601).dateComponents([.yearForWeekOfYear,.weekOfYear,.weekday], from: d); let o = gc(d)
        return CalendarResult(title: t,
            dateLine: String(format: "%04d-W%02d-%d", c.yearForWeekOfYear!, c.weekOfYear!, c.weekday!),
            timeLine: ts(o.hour!, o.minute!, o.second!),
            extraInfo: info3("International standard · Week date format",
                "国際規格 · 週日付形式", "Norme internationale · Format date-semaine", l))
    }

    private func pawukon(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let j = Int(floor(jdn(d)+0.5)); let dc = ((j-146)%210+210)%210

        // Simple cycling weeks: 3,5,6,7
        let triN = ["Pasah","Beteng","Kajeng"]
        let pancaN = ["Umanis","Paing","Pon","Wage","Keliwon"]
        let sadN = ["Tungleh","Aryang","Urukung","Paniron","Was","Maulu"]
        let saptaN = ["Redite","Soma","Anggara","Buda","Wraspati","Sukra","Saniscara"]

        let tri = triN[dc % 3]
        let pancaIdx = dc % 5; let panca = pancaN[pancaIdx]
        let sad = sadN[dc % 6]
        let saptaIdx = dc % 7; let sapta = saptaN[saptaIdx]

        // Urip values for derived weeks (1,2,10)
        let pancaUrip = [9, 7, 4, 8, 5]
        let saptaUrip = [5, 4, 3, 7, 8, 6, 9]
        var uripSum = pancaUrip[pancaIdx] + saptaUrip[saptaIdx] + 1
        if uripSum > 10 { uripSum -= 10 }

        // Ekawara (1-day): Luang if even, void if odd
        let eka = (uripSum % 2 == 0) ? "Luang" : "—"
        // Dwiwara (2-day): Pepet if even, Menga if odd
        let dwi = (uripSum % 2 == 0) ? "Pepet" : "Menga"
        // Dasawara (10-day): match uripSum to day's urip
        let dasaNames = ["Sri","Pati","Raja","Manuh","Duka","Manusa","Raksasa","Suka","Dewa","Pandita"]
        let dasaUrip = [5, 2, 8, 6, 4, 7, 10, 3, 9, 1]
        var dasa = dasaNames[0]
        for i in 0..<10 { if dasaUrip[i] == uripSum { dasa = dasaNames[i]; break } }

        // Caturwara (4-day): simple cycle but day Jaya (index 2) repeats at day 71
        let caturN = ["Sri","Laba","Jaya","Menala"]
        let caturRaw = dc % 4
        let catur: String
        if dc == 71 || dc == 72 { catur = "Jaya" }
        else if dc > 72 { catur = caturN[(dc - 1) % 4] }
        else { catur = caturN[caturRaw] }

        // Astawara (8-day): Kala (index 6) repeats at day 71
        let astaNames = ["Sri","Indra","Guru","Yama","Ludra","Brahma","Kala","Uma"]
        let astaRaw = dc % 8
        let asta: String
        if dc == 71 || dc == 72 { asta = "Kala" }
        else if dc > 72 { asta = astaNames[(dc - 1) % 8] }
        else { asta = astaNames[astaRaw] }

        // Sangawara (9-day): Dangu (index 0) repeats 3x at start (days 0,1,2 all = Dangu)
        let sangaN = ["Dangu","Jangur","Gigis","Nohan","Ogan","Erangan","Urungan","Tulus","Dadi"]
        let sanga: String
        if dc < 3 { sanga = "Dangu" }
        else { sanga = sangaN[(dc - 2) % 9] }

        // Wuku (30 named weeks)
        let wukuNames = ["Sinta","Landep","Ukir","Kulantir","Tolu","Gumbreg","Wariga","Warigadean","Julungwangi","Sungsang",
                         "Dungulan","Kuningan","Langkir","Medangsia","Pujut","Pahang","Krulut","Merakih","Tambir","Medangkungan",
                         "Matal","Uye","Menail","Prangbakat","Bala","Ugu","Wayang","Kelawu","Dukut","Watugunung"]
        let wuku = wukuNames[dc / 7]

        return CalendarResult(title: t,
            dateLine: "Wuku \(wuku) · Day \(dc+1)/210 · \(sapta)-\(panca)",
            timeLine: "\(tri) · \(sad) · \(dasa) · \(dwi) · \(catur) · \(asta) · \(sanga)",
            extraInfo: info3("210-day cycle · All 10 weeks (urip-derived) · \(eka)",
                "210日周期 · 全10種の週（ウリプ算出） · \(eka)",
                "Cycle 210 j · 10 semaines (dérivées par urip) · \(eka)", l))
    }

    private func frRepublican(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let g = cal(.gregorian); let ep = g.date(from: DateComponents(year:1792,month:9,day:22))!
        let ds = Int(d.timeIntervalSince(ep)/86400)
        guard ds>=0 else { return CalendarResult(title:t,dateLine:info3("Before epoch","紀元前","Avant l'époque",l),timeLine:"",extraInfo:"") }
        // Romme leap year rule (Gregorian-like but offset): leap if divisible by 4, except centuries, except 400s
        // Republican year 1 starts Sep 22, 1792. We find the year by iterating.
        func isLeapFR(_ y: Int) -> Bool {
            // Years 3,7,11... were historical leap years. For the general rule (Romme's proposal):
            return (y % 4 == 0) && (y % 100 != 0 || y % 400 == 0)
        }
        func daysInYear(_ y: Int) -> Int { isLeapFR(y) ? 366 : 365 }
        var fy = 1; var rem = ds
        while rem >= daysInYear(fy) { rem -= daysInYear(fy); fy += 1 }
        let diy = rem
        let ms=["Vendémiaire","Brumaire","Frimaire","Nivôse","Pluviôse","Ventôse","Germinal","Floréal","Prairial","Messidor","Thermidor","Fructidor"]
        let dn=["Primidi","Duodi","Tridi","Quartidi","Quintidi","Sextidi","Septidi","Octidi","Nonidi","Décadi"]
        let o=gc(d); let fm:String; let fd:Int
        if diy<360{fm=ms[diy/30];fd=(diy%30)+1}else{fm="Sansculottides";fd=diy-360+1}
        return CalendarResult(title: t, dateLine: "\(dn[min(diy%10,9)]), \(fd) \(fm) An \(fy)",
            timeLine: ts(o.hour!, o.minute!, o.second!),
            extraInfo: info3("12×30 d + 5-6 comp. · 10-day décade · Romme leap rule",
                "12×30日+5-6補完日 · 10日デカード · ロム閏年規則",
                "12×30 j + 5-6 compl. · Décade 10 j · Règle Romme", l))
    }

    private func intlFixed(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let g=cal(.gregorian); let c=g.dateComponents([.year,.hour,.minute,.second],from:d); let y=c.year!
        let sy=g.date(from:DateComponents(year:y,month:1,day:1))!
        var doy=g.dateComponents([.day],from:sy,to:d).day!+1
        let lp=(y%4==0&&y%100 != 0)||(y%400==0)
        let ms=["January","February","March","April","May","June","Sol","July","August","September","October","November","December"]
        let yd=info3("Year Day","年日","Jour de l'An",l)
        let ld=info3("Leap Day","閏日","Jour bissextile",l)
        let inf=info3("13×28 d + Year Day · Kodak until 1989","13×28日+年日 · コダック社1989年まで使用","13×28 j + Jour de l'An · Kodak jusqu'en 1989",l)
        if doy==(lp ? 366:365){return CalendarResult(title:t,dateLine:"\(yd), \(y)",timeLine:ts(c.hour!,c.minute!,c.second!),extraInfo:inf)}
        if lp&&doy==169{return CalendarResult(title:t,dateLine:"\(ld), \(y)",timeLine:ts(c.hour!,c.minute!,c.second!),extraInfo:inf)}
        if lp&&doy>169{doy-=1}
        let m=min((doy-1)/28,12); let dd=((doy-1)%28)+1
        let w=["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][(dd-1)%7]
        return CalendarResult(title:t,dateLine:"\(w), \(ms[m]) \(dd), \(y)",timeLine:ts(c.hour!,c.minute!,c.second!),extraInfo:inf)
    }

    private func positivist(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let g=cal(.gregorian); let c=g.dateComponents([.year,.hour,.minute,.second],from:d)
        let py=c.year!-1788; let sy=g.date(from:DateComponents(year:c.year!,month:1,day:1))!
        let doy=g.dateComponents([.day],from:sy,to:d).day!+1
        let ms=["Moses","Homer","Aristotle","Archimedes","Caesar","St. Paul","Charlemagne","Dante","Gutenberg","Shakespeare","Descartes","Frederick","Bichat"]
        let inf=info3("13×28 d + festivals · Auguste Comte, 1849","13×28日+祭日 · オーギュスト・コント1849年","13×28 j + fêtes · Auguste Comte, 1849",l)
        if doy<=364 {
            let m=(doy-1)/28
            let dd=((doy-1)%28)+1
            let mn = (m<13) ? ms[m] : "Festival"
            return CalendarResult(title:t,dateLine:"\(dd) \(mn), Year \(py)",timeLine:ts(c.hour!,c.minute!,c.second!),extraInfo:inf)
        }
        let f=info3("Festival of the Dead","死者の祭日","Fête des Morts",l)
        return CalendarResult(title:t,dateLine:"\(f), Year \(py)",timeLine:ts(c.hour!,c.minute!,c.second!),extraInfo:inf)
    }

    private func maya(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let j=Int(floor(jdn(d)+0.5))
        let dd=j-584283
        let b=dd/144000
        let r1=dd%144000; let k=r1/7200
        let r2=r1%7200; let tn=r2/360
        let r3=r2%360; let u=r3/20; let ki=r3%20
        let o=gc(d)
        return CalendarResult(title:t, dateLine:"\(b).\(k).\(tn).\(u).\(ki)", timeLine:ts(o.hour!,o.minute!,o.second!),
            extraInfo:info3("Linear · kin/uinal/tun/katun/baktun · GMT correlation",
                "線形 · キン/ウィナル/トゥン/カトゥン/バクトゥン · GMT相関",
                "Linéaire · kin/uinal/tun/katun/baktun · Corrélation GMT",l))
    }

    private func aztecTonal(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let j=Int(floor(jdn(d)+0.5)); let ds=j-584283+159
        let n=((ds-1)%13+13)%13+1; let si=((ds-1)%20+20)%20
        let signs=["Cipactli","Ehecatl","Calli","Cuetzpalin","Coatl","Miquiztli","Mazatl","Tochtli","Atl","Itzcuintli",
                    "Ozomatli","Malinalli","Acatl","Ocelotl","Cuauhtli","Cozcacuauhtli","Ollin","Tecpatl","Quiahuitl","Xochitl"]
        let o=gc(d)
        return CalendarResult(title:t, dateLine:"\(n) \(signs[si])", timeLine:ts(o.hour!,o.minute!,o.second!),
            extraInfo:info3("260-day sacred · 13 × 20 signs","260日祭祀暦 · 13数字×20日符号","Sacré 260 j · 13 × 20 signes",l))
    }

    private func aztecXiuh(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        // Caso correlation with Nicholson's veintena alignment
        // Anchor: 1-Coatl = Fall of Tenochtitlan = Aug 13, 1521 Julian = Aug 23, 1521 Gregorian
        // In Caso-Nicholson: that day is in veintena Tlaxochimaco (10th), day 15
        // Izcalli is the last veintena (Nicholson), Atlcahualo is the first
        // Veintena order: Atlcahualo(1)...Izcalli(18), then 5 Nemontemi

        // Caso anchor in JDN: Aug 13, 1521 Julian = JDN 2277468
        // That day = veintena Tlaxochimaco day 15 → day-in-year = (9*20)+14 = 194 (0-based)
        let anchorJDN = 2277468  // Aug 13, 1521 Julian
        let anchorDayInYear = 194  // 0-based position in xiuhpohualli

        let j = Int(floor(jdn(d) + 0.5))
        let daysSinceAnchor = j - anchorJDN
        // No leap year correction in Caso's system
        let dayInYear = ((daysSinceAnchor + anchorDayInYear) % 365 + 365) % 365

        // Veintena names in Caso-Nicholson order (Atlcahualo first, Izcalli last)
        let ms = ["Atlcahualo","Tlacaxipehualiztli","Tozoztontli","Huey Tozoztli",
                  "Toxcatl","Etzalcualiztli","Tecuilhuitontli","Huey Tecuilhuitl",
                  "Tlaxochimaco","Xocotl Huetzi","Ochpaniztli","Teotleco",
                  "Tepeilhuitl","Quecholli","Panquetzaliztli","Atemoztli","Tititl","Izcalli"]

        // Year bearer calculation (Caso: year named by last day of last veintena)
        // Bearer signs cycle: Tochtli, Acatl, Tecpatl, Calli
        let bearerSigns = ["Tochtli","Acatl","Tecpatl","Calli"]
        // From the anchor (year 3-Calli in Caso), compute current year
        let yearsSinceAnchor = daysSinceAnchor >= 0 ? daysSinceAnchor / 365 : (daysSinceAnchor - 364) / 365
        // 1521 = 3-Calli. Calli index = 3 in bearerSigns, number = 3
        let bearerIdx = ((yearsSinceAnchor + 3) % 4 + 4) % 4  // Calli=3 at anchor
        let bearerNum = ((yearsSinceAnchor + 2) % 13 + 13) % 13 + 1  // 3 at anchor
        let bearer = bearerSigns[bearerIdx]

        let o = gc(d)
        if dayInYear < 360 {
            let veintenaIdx = dayInYear / 20
            let dayInVeintena = (dayInYear % 20) + 1
            return CalendarResult(title: t,
                dateLine: "\(dayInVeintena) \(ms[veintenaIdx]) · Year \(bearerNum)-\(bearer)",
                timeLine: ts(o.hour!, o.minute!, o.second!),
                extraInfo: info3("Caso correlation · 18×20 d + 5 nemontemi · No leap year",
                    "カソ相関 · 18×20日+5ネモンテミ · 閏年なし",
                    "Corrélation Caso · 18×20 j + 5 nemontemi · Sans bissextile", l))
        } else {
            let nemDay = dayInYear - 360 + 1
            return CalendarResult(title: t,
                dateLine: "Nemontemi \(nemDay)/5 · Year \(bearerNum)-\(bearer)",
                timeLine: ts(o.hour!, o.minute!, o.second!),
                extraInfo: info3("Caso correlation · Unlucky nameless days",
                    "カソ相関 · 無名の凶日",
                    "Corrélation Caso · Jours néfastes sans nom", l))
        }
    }

    // MARK: Tibetan Phukpa calendar (Janson formulas, epoch E806)
    // Svante Janson, "Tibetan Calendar Mathematics" (arXiv:1401.6285, 2014)
    // Constants verified against forest-jiang/phugpa-cal reference implementation.

    // Moon equation table (only first quadrant; symmetry derives the rest)
    private let phMoonTab: [Int] = [0, 5, 10, 15, 19, 22, 24, 25]
    private let phSunTab: [Int] = [0, 6, 10, 11]

    private func phMoonTabInt(_ i: Int) -> Int {
        let i2 = ((i % 28) + 28) % 28
        if i2 <= 7 { return phMoonTab[i2] }
        if i2 <= 14 { return phMoonTab[14 - i2] }
        if i2 <= 21 { return -phMoonTab[i2 - 14] }
        return -phMoonTab[28 - i2]
    }
    private func phMoonTabInterp(_ x: Double) -> Double {
        let d = phMoonTabInt(Int(floor(x)))
        let u = phMoonTabInt(Int(ceil(x)))
        return Double(d) + (x - floor(x)) * Double(u - d)
    }
    private func phSunTabInt(_ i: Int) -> Int {
        let i2 = ((i % 12) + 12) % 12
        if i2 <= 3 { return phSunTab[i2] }
        if i2 <= 6 { return phSunTab[6 - i2] }
        if i2 <= 9 { return -phSunTab[i2 - 6] }
        return -phSunTab[12 - i2]
    }
    private func phSunTabInterp(_ x: Double) -> Double {
        let d = phSunTabInt(Int(floor(x)))
        let u = phSunTabInt(Int(ceil(x)))
        return Double(d) + (x - floor(x)) * Double(u - d)
    }

    // Constants (Janson §7, E806)
    private let phM1 = 167025.0 / 5656.0    // mean synodic month ≈ 29.530587
    private let phM0 = 2015501.0 + 4783.0 / 5656.0  // epoch mean date (JD)
    private var phM2: Double { phM1 / 30.0 }  // mean lunar day

    private let phA1 = 253.0 / 3528.0   // moon anomaly increment per month
    private let phA2 = 1.0 / 28.0       // moon anomaly increment per day
    private let phA0 = 475.0 / 3528.0   // moon anomaly at epoch

    private let phS1 = 65.0 / 804.0     // mean sun increment per month
    private var phS2: Double { phS1 / 30.0 }  // mean sun increment per day
    private let phS0 = 743.0 / 804.0    // mean sun at epoch

    // Intercalation constants
    private let phY0 = 806                   // epoch year (Western)
    private let phALPHA = 1.0 + 827.0 / 1005.0  // intercalation alpha
    private let phBETA = 123                 // intercalation beta

    private func phMoonAnom(d: Int, n: Int) -> Double {
        return Double(n) * phA1 + Double(d) * phA2 + phA0
    }
    private func phMoonEqu(d: Int, n: Int) -> Double {
        return phMoonTabInterp(28.0 * phMoonAnom(d: d, n: n))
    }
    private func phMeanSun(d: Int, n: Int) -> Double {
        return Double(n) * phS1 + Double(d) * phS2 + phS0
    }
    private func phSunEqu(d: Int, n: Int) -> Double {
        return phSunTabInterp(12.0 * (phMeanSun(d: d, n: n) - 0.25))
    }
    private func phMeanDate(d: Int, n: Int) -> Double {
        return Double(n) * phM1 + Double(d) * phM2 + phM0
    }
    private func phTrueDate(d: Int, n: Int) -> Double {
        return phMeanDate(d: d, n: n) + phMoonEqu(d: d, n: n) / 60.0 - phSunEqu(d: d, n: n) / 60.0
    }

    /// Convert true month count n → (tibYear, month 1-12, isLeapMonth)
    /// Uses Janson's from_month_count formula (§5)
    private func phFromMonthCount(_ n: Int) -> (year: Int, month: Int, isLeap: Bool) {
        let x = Int(ceil(12.0 * phS1 * Double(n) + phALPHA))
        var M = x % 12; if M == 0 { M = 12 }  // amod(x, 12)
        let Y = (x - M) / 12 + phY0 + 127  // Tibetan year = Western + 127
        let xNext = Int(ceil(12.0 * phS1 * Double(n + 1) + phALPHA))
        let isLeap = (xNext == x)
        return (Y, M, isLeap)
    }

    /// Reverse: (tibYear, month, isLeap) → true month count n
    private func phToMonthCount(Y: Int, M: Int, isLeap: Bool) -> Int {
        let wY = Y - 127  // Western year
        let l = isLeap ? 1.0 : 0.0
        return Int(floor((12.0 * Double(wY - phY0) + Double(M) - phALPHA - (1.0 - 12.0 * phS1) * l) / (12.0 * phS1)))
    }

    /// Whether Tibetan year Y, month M has a leap month preceding it
    private func phHasLeapMonth(Y: Int, M: Int) -> Bool {
        let Mp = 12 * (Y - 127 - phY0) + M
        let r = ((2 * Mp) % 65 + 65) % 65
        let b = phBETA % 65
        return r == b || r == (b + 1) % 65
    }

    private func tibetan(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let targetJD = jdn(d)
        let targetJDN = Int(floor(targetJD))  // floor, matching reference impl

        // Estimate month count from JD
        let approxN = Int(round((targetJD - phM0) / phM1))

        // Search for correct month (the one whose day 30 JD >= targetJDN)
        var bestN = approxN; var bestD = 1

        for delta in -3...3 {
            let n = approxN + delta
            // First day of month: JD after day 30 of previous month
            let monthStartJD = 1 + Int(floor(phTrueDate(d: 30, n: n - 1)))
            let monthEndJD = Int(floor(phTrueDate(d: 30, n: n)))
            if targetJDN >= monthStartJD && targetJDN <= monthEndJD {
                bestN = n
                // Find lunar day: search d=1..30 for the one ending on targetJDN
                for dd in 1...30 {
                    let tdJD = Int(floor(phTrueDate(d: dd, n: n)))
                    if tdJD >= targetJDN {
                        bestD = dd
                        break
                    }
                }
                break
            }
        }

        // Detect skipped and doubled tshes
        let prevD: (Int, Int) = bestD == 1 ? (30, bestN - 1) : (bestD - 1, bestN)
        let prevJD = Int(floor(phTrueDate(d: prevD.0, n: prevD.1)))
        let currJD = Int(floor(phTrueDate(d: bestD, n: bestN)))
        let isSkipped = (currJD == prevJD)  // two lunar days end on same solar day → first skipped
        let isDoubled = (currJD == prevJD + 2)  // lunar day spans two solar days → doubled

        // Year, month, leap
        let (tibYear, rawMonth, isLeap) = phFromMonthCount(bestN)

        // 60-year cycle: element + animal + gender
        // Tibetan year Y → cycle index = (Y+1) mod 12 for animal, etc.
        let elEN=["Wood","Wood","Fire","Fire","Earth","Earth","Iron","Iron","Water","Water"]
        let elJA=["木","木","火","火","土","土","鉄","鉄","水","水"]
        let elFR=["Bois","Bois","Feu","Feu","Terre","Terre","Fer","Fer","Eau","Eau"]
        let anEN=["Mouse","Ox","Tiger","Rabbit","Dragon","Snake","Horse","Sheep","Monkey","Bird","Dog","Pig"]
        let anJA=["鼠","牛","虎","兎","龍","蛇","馬","羊","猿","鳥","犬","猪"]
        let anFR=["Souris","Bœuf","Tigre","Lapin","Dragon","Serpent","Cheval","Mouton","Singe","Oiseau","Chien","Cochon"]
        let gEN=["Male","Female"]; let gJA=["陽","陰"]; let gFR=["Mâle","Femelle"]

        let animal = ((tibYear + 1) % 12 + 12) % 12
        let element = (((tibYear - 1) / 2) % 5 + 5) % 5
        let gender = ((tibYear + 1) % 2 + 2) % 2
        let el: String; let an: String; let gn: String
        switch l {
        case .en: el=elEN[element]; an=anEN[animal]; gn=gEN[gender]
        case .ja: el=elJA[element]; an=anJA[animal]; gn=gJA[gender]
        case .fr: el=elFR[element]; an=anFR[animal]; gn=gFR[gender]
        }

        let o = gc(d)

        let lpS: String
        switch l {
        case .en: lpS = isLeap ? "Leap " : ""
        case .ja: lpS = isLeap ? "閏" : ""
        case .fr: lpS = isLeap ? "Intercal. " : ""
        }

        let skipInfo: String
        if isSkipped {
            switch l { case .en: skipInfo=" [skipped]"; case .ja: skipInfo=" [跳日]"; case .fr: skipInfo=" [sauté]" }
        } else if isDoubled {
            switch l { case .en: skipInfo=" [doubled]"; case .ja: skipInfo=" [重日]"; case .fr: skipInfo=" [doublé]" }
        } else { skipInfo = "" }

        return CalendarResult(title: t,
            dateLine: "\(gn) \(el)-\(an) · \(lpS)Month \(rawMonth), Day \(bestD)\(skipInfo)",
            timeLine: "Year \(tibYear) (Royal) · \(ts(o.hour!,o.minute!,o.second!))",
            extraInfo: info3("Phukpa (Janson) · 67/65 intercalation · Skipped/doubled tshes",
                "プクパ体系（ヤンソン式） · 67/65置閏 · 跳日・重日",
                "Phukpa (Janson) · Intercalation 67/65 · Tshes sautés/doublés", l))
    }

    // Time-based
    private func sumerian(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let f=dayFrac(d);let tu=f*360;let u=Int(tu);let g=Int((tu-Double(u))*60); let o=gc(d)
        return CalendarResult(title:t, dateLine:"\(u) UŠ \(g) GESH (/ 360)", timeLine:"≈ \(ts(o.hour!,o.minute!,o.second!))",
            extraInfo:info3("Base-60 · Origin of 60 min/hr, 60 sec/min","六十進法 · 1時間60分の起源","Base 60 · Origine des 60 min/h",l))
    }

    private func egyptian(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let o=gc(d); let tm=o.hour!*60+o.minute!; let day=tm>=360&&tm<1080
        let h:Int; let p:String
        if day{h=min((tm-360)/60+1,12); p=info3("Day","昼","Jour",l)}
        else{let nm=(tm>=1080) ? tm-1080 : tm+360; h=min(nm/60+1,12); p=info3("Night","夜","Nuit",l)}
        return CalendarResult(title:t, dateLine:"\(p) — Hour \(h) / 12", timeLine:"≈ \(ts(o.hour!,o.minute!,o.second!))",
            extraInfo:info3("12 day + 12 night hrs · Varies by season","昼12+夜12時辰 · 季節で変化","12 h jour + 12 h nuit · Variable selon saison",l))
    }

    private func ke(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let f=dayFrac(d);let tk=f*100;let k=Int(tk); let o=gc(d)
        let sh=["Zi","Chou","Yin","Mao","Chen","Si","Wu","Wei","Shen","You","Xu","Hai"]
        let shJa=["子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"]
        let i=o.hour!/2; let sc:String
        switch l{case .ja:sc="\(shJa[i%12])の刻";default:sc=sh[i%12]}
        return CalendarResult(title:t, dateLine:"Ke \(k) · \(sc)", timeLine:"≈ \(ts(o.hour!,o.minute!,o.second!))",
            extraInfo:info3("100 ke/day (14.4 min) · 12 double-hours","1日100刻（14.4分） · 十二時辰","100 ke/jour (14,4 min) · 12 doubles-heures",l))
    }

    private func ghati(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let f=dayFrac(d);let tg=f*60;let g=Int(tg);let p=Int((tg-Double(g))*60); let o=gc(d)
        return CalendarResult(title:t, dateLine:"\(g) Ghati \(p) Pala", timeLine:"≈ \(ts(o.hour!,o.minute!,o.second!))",
            extraInfo:info3("60 Ghati/day (~24 min) · 60 Pala/Ghati","1日60ガティ（約24分） · 60パラ/ガティ","60 Ghati/jour (~24 min) · 60 Pala/Ghati",l))
    }

    private func decimal(_ d: Date, _ l: AppLanguage, _ t: String) -> CalendarResult {
        let f=dayFrac(d);let dH=Int(f*10);let dM=Int((f*10-Double(dH))*100);let dS=Int(((f*10-Double(dH))*100-Double(dM))*100)
        let o=gc(d)
        return CalendarResult(title:t, dateLine:String(format:"%d:%02d:%02d (decimal)",dH,dM,dS),
            timeLine:"≈ \(ts(o.hour!,o.minute!,o.second!))",
            extraInfo:info3("10 h/day · 100 min/h · 100 sec/min · 1793-1806","1日10時間 · 100分/時 · 100秒/分 · 1793-1806年","10 h/jour · 100 min/h · 100 sec/min · 1793-1806",l))
    }
}

// MARK: - Festival Data

struct FestivalEntry {
    let cal: CalendarSystem
    let calID: Calendar.Identifier?  // nil = manual calendars (pawukon, aztec, maya, tibetan, french rep, etc.)
    let month: Int       // month number in the respective calendar (0 = any/not matchable)
    let dayStart: Int    // first day (0 = not matchable by day)
    let dayEnd: Int      // last day of range (same as dayStart for single-day)
    let name: String
    let en: String; let ja: String; let fr: String
    func desc(_ l: AppLanguage) -> String { switch l { case .en: return en; case .ja: return ja; case .fr: return fr } }
}

struct FestivalDB {
    // Helper to create entries concisely
    private static func E(_ cal: CalendarSystem, _ cid: Calendar.Identifier?, _ m: Int, _ d1: Int, _ d2: Int, _ name: String, _ en: String, _ ja: String, _ fr: String) -> FestivalEntry {
        FestivalEntry(cal:cal, calID:cid, month:m, dayStart:d1, dayEnd:d2, name:name, en:en, ja:ja, fr:fr)
    }

    static let all: [FestivalEntry] = [
        // Gregorian (month/day in .gregorian)
        E(.gregorian,.gregorian,1,1,1,"New Year's Day","January 1","1月1日 — 新年","1er janvier — Jour de l'An"),
        E(.gregorian,.gregorian,2,14,14,"Valentine's Day","February 14","2月14日 — バレンタインデー","14 février — Saint-Valentin"),
        E(.gregorian,.gregorian,5,1,1,"International Workers' Day","May 1 — Labour Day","5月1日 — メーデー","1er mai — Fête du Travail"),
        E(.gregorian,.gregorian,12,25,25,"Christmas","December 25","12月25日 — クリスマス","25 décembre — Noël"),
        // Julian (dates are in Gregorian equivalent for matching)
        E(.julian,.gregorian,1,7,7,"Orthodox Christmas","Jan 7 (Greg.)","1月7日 — 正教会のクリスマス","7 janv. — Noël orthodoxe"),
        E(.julian,.gregorian,1,14,14,"Orthodox New Year","Jan 14 (Greg.)","1月14日 — 正教会の新年","14 janv. — Nouvel An orthodoxe"),
        E(.julian,.gregorian,1,19,19,"Theophany","Jan 19 (Greg.)","1月19日 — 神現祭","19 janv. — Théophanie"),
        E(.julian,.gregorian,8,19,19,"Transfiguration","Aug 19 (Greg.)","8月19日 — 主の変容","19 août — Transfiguration"),
        // Chinese Lunar (month/day in .chinese)
        E(.chinese,.chinese,1,1,1,"Spring Festival","Lunar New Year","正月初一 — 春節","Fête du Printemps"),
        E(.chinese,.chinese,1,15,15,"Lantern Festival","1st/15 — Lanterns, tangyuan","正月十五 — 元宵節","1er/15 — Fête des Lanternes"),
        E(.chinese,.chinese,5,5,5,"Dragon Boat Festival","5th/5 — Dragon boats, zongzi","五月初五 — 端午節","5e/5 — Bateaux-Dragons"),
        E(.chinese,.chinese,7,7,7,"Qixi","7th/7 — Chinese Valentine's Day","七月初七 — 七夕","7e/7 — Qixi"),
        E(.chinese,.chinese,7,15,15,"Ghost Festival","7th/15 — Hungry Ghost Festival","七月十五 — 中元節","7e/15 — Fête des Fantômes"),
        E(.chinese,.chinese,8,15,15,"Mid-Autumn Festival","8th/15 — Mooncakes","八月十五 — 中秋節","8e/15 — Mi-Automne"),
        E(.chinese,.chinese,9,9,9,"Double Ninth","9th/9 — Climbing heights","九月初九 — 重陽節","9e/9 — Double Neuf"),
        E(.chinese,.chinese,12,8,8,"Laba Festival","12th/8 — Laba congee","十二月初八 — 臘八節","12e/8 — Fête de Laba"),
        E(.chinese,.chinese,12,30,30,"New Year's Eve","12th/30 — Reunion dinner","十二月三十 — 除夜","12e/30 — Réveillon lunaire"),
        // Hebrew (month/day in .hebrew)
        E(.hebrew,.hebrew,1,1,2,"Rosh Hashanah","1-2 Tishrei — New Year","ティシュレー月1-2日 — 新年","1-2 Tichri — Roch Hachana"),
        E(.hebrew,.hebrew,1,10,10,"Yom Kippur","10 Tishrei — Atonement","ティシュレー月10日 — 贖罪の日","10 Tichri — Yom Kippour"),
        E(.hebrew,.hebrew,1,15,21,"Sukkot","15-21 Tishrei — Booths","ティシュレー月15-21日 — 仮庵の祭り","15-21 Tichri — Souccot"),
        E(.hebrew,.hebrew,3,25,30,"Hanukkah (start)","25 Kislev — Lights","キスレーウ月25日〜 — ハヌカー","25 Kislev — Hanoucca"),
        E(.hebrew,.hebrew,6,14,14,"Purim","14 Adar — Lots","アダル月14日 — プリム祭","14 Adar — Pourim"),
        E(.hebrew,.hebrew,8,15,22,"Passover","15-22 Nisan — Exodus","ニサン月15-22日 — 過越祭","15-22 Nissan — Pessa'h"),
        E(.hebrew,.hebrew,10,6,7,"Shavuot","6-7 Sivan — Torah","シヴァン月6-7日 — シャヴオット","6-7 Sivan — Chavouot"),
        // Islamic (month/day in .islamicUmmAlQura)
        E(.islamic,.islamicUmmAlQura,1,1,1,"Islamic New Year","1 Muharram","ムハッラム月1日 — 新年","1er Mouharram — Nouvel An"),
        E(.islamic,.islamicUmmAlQura,1,10,10,"Ashura","10 Muharram","ムハッラム月10日 — アーシューラー","10 Mouharram — Achoura"),
        E(.islamic,.islamicUmmAlQura,3,12,12,"Mawlid an-Nabi","12 Rabi al-Awwal","ラビーウ月12日 — 預言者誕生祭","12 Rabi al-Awwal — Mawlid"),
        E(.islamic,.islamicUmmAlQura,10,1,1,"Eid al-Fitr","1 Shawwal","シャウワール月1日 — 断食明け","1er Chawwal — Aïd el-Fitr"),
        E(.islamic,.islamicUmmAlQura,12,10,13,"Eid al-Adha","10-13 Dhu al-Hijjah","ズー・アル＝ヒッジャ月10-13日 — 犠牲祭","10-13 Dhou al-Hijja — Aïd al-Adha"),
        // Persian (month/day in .persian)
        E(.persian,.persian,1,1,1,"Nowruz","1 Farvardin — New Year","ファルヴァルディーン月1日 — ノウルーズ","1er Farvardin — Norouz"),
        E(.persian,.persian,1,13,13,"Sizdah Bedar","13 Farvardin — Nature Day","ファルヴァルディーン月13日 — スィーズダ・ベダル","13 Farvardin — Sizdah Bedar"),
        E(.persian,.persian,7,16,16,"Mehregan","16 Mehr — Mithra","メフル月16日 — メフレガーン","16 Mehr — Mehregan"),
        // Buddhist (month/day in .buddhist = gregorian+543, same month/day)
        E(.buddhist,.gregorian,4,13,15,"Songkran","Apr 13-15 — Water festival","4月13-15日 — ソンクラーン","13-15 avr. — Songkran"),
        E(.buddhist,.gregorian,12,8,8,"Bodhi Day","Dec 8 — Enlightenment","12月8日 — 成道会","8 déc. — Bodhi"),
        // Japanese (month/day in .gregorian since japanese calendar uses same months)
        E(.japanese,.gregorian,1,1,3,"Shōgatsu","Jan 1-3 — New Year","1月1-3日 — 正月","1er-3 janv. — Shōgatsu"),
        E(.japanese,.gregorian,2,3,3,"Setsubun","~Feb 3 — Bean-throwing","2月3日 — 節分","~3 fév. — Setsubun"),
        E(.japanese,.gregorian,2,23,23,"Emperor's Birthday","Feb 23 — Tennō Tanjōbi","2月23日 — 天皇誕生日","23 fév. — Anniversaire de l'Empereur"),
        E(.japanese,.gregorian,3,3,3,"Hinamatsuri","Mar 3 — Girls' Day","3月3日 — 雛祭り","3 mars — Hinamatsuri"),
        E(.japanese,.gregorian,5,5,5,"Kodomo no Hi","May 5 — Children's Day","5月5日 — こどもの日","5 mai — Kodomo no Hi"),
        E(.japanese,.gregorian,7,7,7,"Tanabata","Jul 7 — Star Festival","7月7日 — 七夕","7 juil. — Tanabata"),
        E(.japanese,.gregorian,11,15,15,"Shichi-Go-San","Nov 15 — Children 3,5,7","11月15日 — 七五三","15 nov. — Shichi-Go-San"),
        E(.japanese,.gregorian,12,31,31,"Ōmisoka","Dec 31 — New Year's Eve","12月31日 — 大晦日","31 déc. — Ōmisoka"),
        // ROC (same gregorian months)
        E(.roc,.gregorian,1,1,1,"Founding Day","Jan 1","1月1日 — 開国記念日","1er janv. — Fondation"),
        E(.roc,.gregorian,2,28,28,"Peace Memorial Day","Feb 28 — 228 Incident","2月28日 — 和平記念日","28 fév. — Journée de la Paix"),
        E(.roc,.gregorian,10,10,10,"National Day","Oct 10 — Double Tenth","10月10日 — 国慶日","10 oct. — Fête nationale"),
        // Coptic (month/day in .coptic)
        E(.coptic,.coptic,1,1,1,"Nayrouz","1 Tout — Coptic New Year","トゥート月1日 — コプト新年","1er Tout — Nayrouz"),
        E(.coptic,.coptic,4,29,29,"Nativity","29 Kiahk","コイアク月29日 — 聖誕節","29 Kiahk — Noël copte"),
        // Ethiopic (month/day in .ethiopicAmeteMihret)
        E(.ethiopic,.ethiopicAmeteMihret,1,1,1,"Enkutatash","1 Meskerem — New Year","メスケレム月1日 — エンクタターシュ","1er Meskerem — Enkutatash"),
        E(.ethiopic,.ethiopicAmeteMihret,1,17,17,"Meskel","17 Meskerem — True Cross","メスケレム月17日 — メスケル","17 Meskerem — Meskel"),
        E(.ethiopic,.ethiopicAmeteMihret,5,11,11,"Timkat","11 Ter — Epiphany","テル月11日 — ティムカット","11 Ter — Timkat"),
        // Indian (month/day in .indian)
        E(.indian,.indian,1,1,1,"Chaitra 1","1 Chaitra — Saka New Year","チャイトラ月1日 — サカ暦新年","1er Chaitra — Nouvel An Saka"),
        // Pawukon (day-in-cycle matching)
        E(.pawukon,nil,0,74,74,"Galungan","Wed, wuku Dungulan — Dharma victory","ドゥングラン水曜 — ガルンガン","Mer. Dungulan — Galungan"),
        E(.pawukon,nil,0,84,84,"Kuningan","10 days after Galungan","ガルンガン10日後 — クニンガン","10 j après Galungan — Kuningan"),
        E(.pawukon,nil,0,209,209,"Saraswati","Sat of Watugunung","ワトゥグヌン土曜 — サラスワティ","Sam. Watugunung — Saraswati"),
    ]

    /// Match festivals for today based on selected calendars
    static func todaysFestivals(date: Date, calendars: [CalendarSystem], lang: AppLanguage) -> [(name: String, desc: String)] {
        let calSet = Set(calendars)
        var results: [(String, String)] = []

        for entry in all {
            guard calSet.contains(entry.cal) else { continue }
            guard entry.month > 0 || entry.cal == .pawukon else { continue }

            if entry.cal == .pawukon {
                // Pawukon: match by day-in-cycle
                let j = Int(floor(date.timeIntervalSince1970 / 86400.0 + 2440587.5 + 0.5))
                let dc = ((j - 146) % 210 + 210) % 210
                if dc >= entry.dayStart && dc <= entry.dayEnd {
                    results.append((entry.name, entry.desc(lang)))
                }
                continue
            }

            guard let calID = entry.calID else { continue }

            var cal = Calendar(identifier: calID)
            cal.timeZone = .current
            let comps = cal.dateComponents([.month, .day], from: date)
            guard let m = comps.month, let d = comps.day else { continue }

            if m == entry.month && d >= entry.dayStart && d <= entry.dayEnd {
                results.append((entry.name, entry.desc(lang)))
            }
        }
        return results
    }
}


// ============================================================================
// APP STATE, VIEWS, AND MENU BAR INFRASTRUCTURE
// ============================================================================


// MARK: - App State

enum BackgroundMode: String, CaseIterable, Codable { case papyrus, solidColor }

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var menuBarCalendars: [CalendarSystem] = [.gregorian, .chinese, .persian] {
        didSet { save() }
    }
    @Published var backgroundMode: BackgroundMode = .papyrus {
        didSet { save() }
    }
    @Published var backgroundColor: NSColor = .windowBackgroundColor {
        didSet { save() }
    }
    @Published var fontColor: NSColor = .labelColor {
        didSet { save() }
    }
    @Published var useCustomFontColor: Bool = false {
        didSet { save() }
    }
    @Published var currentDate = Date()
    @Published var language: AppLanguage = .en {
        didSet { save() }
    }
    @Published var showSettings = false
    private var timer: Timer?
    var l10n: L10n { L10n(lang: language) }

    private let defaults = UserDefaults.standard
    private var isLoading = true  // suppress save() during init

    init() {
        // Load saved settings (didSet fires but save() is suppressed by isLoading flag)
        if let raw = defaults.stringArray(forKey: "menuBarCalendars") {
            let parsed = raw.compactMap { CalendarSystem(rawValue: $0) }
            if !parsed.isEmpty { menuBarCalendars = parsed }
        }
        if let raw = defaults.string(forKey: "backgroundMode"), let m = BackgroundMode(rawValue: raw) {
            backgroundMode = m
        }
        if let data = defaults.data(forKey: "backgroundColor"), let c = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
            backgroundColor = c
        }
        if let data = defaults.data(forKey: "fontColor"), let c = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
            fontColor = c
        }
        useCustomFontColor = defaults.bool(forKey: "useCustomFontColor")
        if let raw = defaults.string(forKey: "language"), let lang = AppLanguage(rawValue: raw) {
            language = lang
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.currentDate = Date() }
        }
        isLoading = false
    }

    private func save() {
        guard !isLoading else { return }
        defaults.set(menuBarCalendars.map { $0.rawValue }, forKey: "menuBarCalendars")
        defaults.set(backgroundMode.rawValue, forKey: "backgroundMode")
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: backgroundColor, requiringSecureCoding: false) {
            defaults.set(data, forKey: "backgroundColor")
        }
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: fontColor, requiringSecureCoding: false) {
            defaults.set(data, forKey: "fontColor")
        }
        defaults.set(useCustomFontColor, forKey: "useCustomFontColor")
        defaults.set(language.rawValue, forKey: "language")
    }

    func setMenuBarCalendar(at i: Int, to s: CalendarSystem) {
        guard i < menuBarCalendars.count else { return }
        menuBarCalendars[i] = s
    }
    func addMenuBarCalendar() {
        guard menuBarCalendars.count < 3 else { return }
        let used = Set(menuBarCalendars)
        menuBarCalendars.append(CalendarSystem.allCases.first { !used.contains($0) } ?? .gregorian)
    }
    func removeMenuBarCalendar() {
        guard menuBarCalendars.count > 1 else { return }
        menuBarCalendars.removeLast()
    }
}

// MARK: - Papyrus Background

struct PapyrusBackground: View {
    @Environment(\.colorScheme) var cs
    var body: some View {
        Canvas { ctx, size in
            let base: Color = cs == .dark
                ? Color(red: 0.15, green: 0.12, blue: 0.08)
                : Color(red: 0.93, green: 0.88, blue: 0.78)
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(base))
            let r = SRng()
            for _ in 0..<200 {
                var p = Path()
                let x = r.n(size.width); let y = r.n(size.height)
                p.move(to: CGPoint(x: x, y: y))
                p.addLine(to: CGPoint(x: x + r.n(60) - 30, y: y + r.n(4) - 2))
                ctx.stroke(p, with: .color(Color.brown.opacity(cs == .dark ? 0.08 : 0.12)), lineWidth: 0.5)
            }
            for _ in 0..<150 {
                var p = Path()
                let x = r.n(size.width); let y = r.n(size.height)
                p.move(to: CGPoint(x: x, y: y))
                p.addLine(to: CGPoint(x: x + r.n(2), y: y + r.n(80)))
                ctx.stroke(p, with: .color(Color.brown.opacity(cs == .dark ? 0.06 : 0.08)), lineWidth: 0.3)
            }
        }
    }
}

class SRng {
    var s: UInt64
    init(seed: UInt64 = 0) {
        // Use a date-derived seed for subtle variation per launch, or fallback
        if seed == 0 {
            s = UInt64(Date().timeIntervalSince1970 * 1000) | 1
        } else {
            s = seed
        }
    }
    func n(_ m: CGFloat) -> CGFloat {
        s = s &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(Double((s >> 33) & 0x7FFFFFFF) / Double(0x7FFFFFFF)) * m
    }
}

// MARK: - Calendar Card (compact, for both main window and popover)

struct CalendarCardView: View {
    let result: CalendarResult
    let compact: Bool
    let fontColor: Color
    @Environment(\.colorScheme) var cs

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            Text(result.title)
                .font(.system(size: compact ? 11 : 13, weight: .semibold, design: .serif))
                .foregroundColor(fontColor.opacity(0.6))
            Text(result.dateLine)
                .font(.system(size: compact ? 15 : 20, weight: .bold, design: .serif))
                .foregroundColor(fontColor)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text(result.timeLine)
                .font(.system(size: compact ? 12 : 15, weight: .medium, design: .monospaced))
                .foregroundColor(fontColor.opacity(0.8))
            if !compact {
                Text(result.extraInfo)
                    .font(.system(size: 10, weight: .regular, design: .serif))
                    .foregroundColor(fontColor.opacity(0.45))
                    .lineLimit(2)
            }
        }
        .padding(compact ? 10 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cs == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        )
    }
}

// MARK: - Festival Section

struct FestivalSectionView: View {
    @ObservedObject var state: AppState
    let fontColor: Color
    let calendars: [CalendarSystem]
    @Environment(\.colorScheme) var cs

    var body: some View {
        let matches = FestivalDB.todaysFestivals(date: state.currentDate, calendars: calendars, lang: state.language)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(fontColor.opacity(0.5))
                Text(state.l10n.todaysFestivals)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundColor(fontColor.opacity(0.6))
            }
            if matches.isEmpty {
                Text(state.l10n.noFestivals)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(fontColor.opacity(0.35))
            } else {
                ForEach(Array(matches.enumerated()), id: \.offset) { _, f in
                    HStack(alignment: .top, spacing: 6) {
                        Circle().fill(Color.orange.opacity(0.6)).frame(width: 5, height: 5).padding(.top, 4)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(f.name)
                                .font(.system(size: 12, weight: .semibold, design: .serif))
                                .foregroundColor(fontColor.opacity(0.85))
                            Text(f.desc)
                                .font(.system(size: 10, design: .serif))
                                .foregroundColor(fontColor.opacity(0.5))
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cs == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.3))
        )
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(state.l10n.settings)
                .font(.headline)

            // Language
            HStack {
                Text(state.l10n.language)
                Spacer()
                Picker("", selection: $state.language) {
                    ForEach(AppLanguage.allCases) { l in Text(l.rawValue).tag(l) }
                }.frame(width: 120).labelsHidden()
            }

            // Background
            HStack {
                Text(state.l10n.background)
                Spacer()
                Picker("", selection: $state.backgroundMode) {
                    Text("Papyrus").tag(BackgroundMode.papyrus)
                    Text("Solid").tag(BackgroundMode.solidColor)
                }.frame(width: 120).labelsHidden()
            }

            if state.backgroundMode == .solidColor {
                ColorPicker("Background color", selection: Binding(
                    get: { Color(state.backgroundColor) },
                    set: { state.backgroundColor = NSColor($0) }
                ))
            }

            // Font color
            Toggle("Custom font color", isOn: $state.useCustomFontColor)
            if state.useCustomFontColor {
                ColorPicker("Font color", selection: Binding(
                    get: { Color(state.fontColor) },
                    set: { state.fontColor = NSColor($0) }
                ))
            }

            Divider()

            // Menu bar calendar selection
            Text(state.l10n.menuBarSelection)
                .font(.subheadline.weight(.semibold))

            ForEach(Array(state.menuBarCalendars.enumerated()), id: \.offset) { idx, sys in
                Picker("Slot \(idx + 1)", selection: Binding(
                    get: { sys },
                    set: { state.setMenuBarCalendar(at: idx, to: $0) }
                )) {
                    ForEach(CalendarSystem.allCases) { s in
                        Text(s.displayName(state.language)).tag(s)
                    }
                }
            }
            HStack {
                if state.menuBarCalendars.count < 3 {
                    Button("+ Add") { state.addMenuBarCalendar() }
                }
                if state.menuBarCalendars.count > 1 {
                    Button("− Remove") { state.removeMenuBarCalendar() }
                }
            }

            Spacer()
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380, height: 520)
    }
}

// MARK: - Main Window (all 27 calendars)

struct MainWindowView: View {
    @ObservedObject var state: AppState
    @Environment(\.colorScheme) var cs

    var fc: Color {
        state.useCustomFontColor ? Color(state.fontColor)
            : (cs == .dark ? .white : Color(red: 0.15, green: 0.1, blue: 0.05))
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            // Background
            switch state.backgroundMode {
            case .papyrus: PapyrusBackground()
            case .solidColor: Color(state.backgroundColor)
            }

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.l10n.appSubtitle)
                            .font(.system(size: 9, weight: .bold, design: .serif))
                            .tracking(4)
                            .foregroundColor(fc.opacity(0.35))
                        Text(state.l10n.appTitle)
                            .font(.system(size: 22, weight: .light, design: .serif))
                            .foregroundColor(fc)
                    }
                    Spacer()
                    // Language picker + settings gear
                    HStack(spacing: 8) {
                        Picker("", selection: $state.language) {
                            ForEach(AppLanguage.allCases) { l in Text(l.rawValue).tag(l) }
                        }.frame(width: 100).labelsHidden()

                        Button(action: { state.showSettings = true }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14))
                                .foregroundColor(fc.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 6)

                Divider().padding(.horizontal, 20)

                // All calendars grid
                ScrollView {
                    VStack(spacing: 12) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(CalendarSystem.allCases) { sys in
                                CalendarCardView(
                                    result: CalendarEngine.shared.compute(sys, date: state.currentDate, lang: state.language),
                                    compact: true,
                                    fontColor: fc
                                )
                            }
                        }

                        // Festival section (matches against ALL calendars)
                        FestivalSectionView(
                            state: state,
                            fontColor: fc,
                            calendars: CalendarSystem.allCases.map { $0 }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $state.showSettings) {
            SettingsView(state: state)
        }
    }
}

// MARK: - Menu Bar Popover Content

struct MenuBarPopoverView: View {
    @ObservedObject var state: AppState
    @Environment(\.colorScheme) var cs

    var fc: Color { cs == .dark ? .white : Color(red: 0.15, green: 0.1, blue: 0.05) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(state.l10n.appTitle)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                Spacer()
                Text(TimeZone.current.identifier)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Selected calendars
            ForEach(Array(state.menuBarCalendars.enumerated()), id: \.offset) { _, sys in
                let result = CalendarEngine.shared.compute(sys, date: state.currentDate, lang: state.language)
                CalendarCardView(result: result, compact: true, fontColor: fc)
            }

            // Festival matches for menu bar calendars
            let matches = FestivalDB.todaysFestivals(date: state.currentDate, calendars: state.menuBarCalendars, lang: state.language)
            if !matches.isEmpty {
                Divider()
                ForEach(Array(matches.enumerated()), id: \.offset) { _, f in
                    HStack(spacing: 4) {
                        Circle().fill(Color.orange.opacity(0.6)).frame(width: 4, height: 4)
                        Text(f.name)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                        Text("— \(f.desc)")
                            .font(.system(size: 10, design: .serif))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Divider()

            // Open main window button
            Button(action: {
                NSApp.activate(ignoringOtherApps: true)
                WindowHelper.openMainWindow()
            }) {
                HStack {
                    Image(systemName: "macwindow")
                    Text(state.l10n.openWindow)
                }
                .font(.system(size: 12))
            }
            .buttonStyle(.plain)

            Button(action: { NSApp.terminate(nil) }) {
                HStack {
                    Image(systemName: "power")
                    Text(state.l10n.quit)
                }
                .font(.system(size: 12))
                .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 340)
    }
}

// MARK: - App Delegate (keeps app alive in background)

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        WindowHelper.openMainWindow()
    }
}

enum WindowHelper {
    static let mainID = NSUserInterfaceItemIdentifier("U4BIA-Main")
    private static var mainWindow: NSWindow?

    static func openMainWindow() {
        // If we already have a live window, just show it
        if let w = mainWindow, w.isVisible || !w.isReleasedWhenClosed {
            w.makeKeyAndOrderFront(nil)
            return
        }
        // Also check NSApp.windows in case something else created it
        for w in NSApp.windows where w.identifier == mainID {
            mainWindow = w
            w.makeKeyAndOrderFront(nil)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered, defer: false
        )
        window.identifier = mainID
        window.title = "U\u{2084}-BI-A"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: MainWindowView(state: AppState.shared))
        window.makeKeyAndOrderFront(nil)
        mainWindow = window
    }
}

// MARK: - App Entry

@main
struct U4BIA_App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject private var state = AppState.shared

    var body: some Scene {
        // Menu bar extra (status bar with live date text + popover)
        MenuBarExtra {
            MenuBarPopoverView(state: state)
        } label: {
            Text(menuBarLabel)
                .font(.system(size: 12, design: .default))
        }
        .menuBarExtraStyle(.window)
    }

    /// Builds the status bar text from selected calendars
    private var menuBarLabel: String {
        let engine = CalendarEngine.shared
        let parts = state.menuBarCalendars.map { sys -> String in
            let r = engine.compute(sys, date: state.currentDate, lang: state.language)
            // Use a shortened version: calendar short name + date
            return "\(shortName(sys)) \(r.dateLine)"
        }
        return parts.joined(separator: "  ·  ")
    }

    private func shortName(_ sys: CalendarSystem) -> String {
        switch sys {
        case .gregorian: return "🌍"
        case .julian: return "📜"
        case .chinese: return "🌙"
        case .hebrew: return "✡️"
        case .islamic: return "☪️"
        case .persian: return "🔆"
        case .buddhist: return "☸️"
        case .japanese: return "🎌"
        case .roc: return "🏛"
        case .julianDay: return "JD"
        case .coptic: return "☦️"
        case .ethiopic: return "🇪🇹"
        case .indian: return "🇮🇳"
        case .iso8601: return "ISO"
        case .pawukon: return "🌺"
        case .frenchRepublican: return "🇫🇷"
        case .internationalFixed: return "IFC"
        case .positivist: return "📐"
        case .mayaLongCount: return "🏛"
        case .aztecTonalpohualli: return "☀️"
        case .aztecXiuhpohualli: return "🌽"
        case .tibetan: return "🏔"
        case .sumerianSexagesimal: return "𒀭"
        case .egyptianHours: return "🏺"
        case .chineseKe: return "⏳"
        case .indianGhati: return "🕉"
        case .decimalTime: return "⑩"
        }
    }
}

// End of file
