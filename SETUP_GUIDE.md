# MetalPriceTracker 설정 가이드

LME 비철금속 시세 추적 iOS 앱

---

## 1단계: 사전 준비

### 필요한 것
- **Mac 컴퓨터** (SwiftUI 개발 필수)
- **Xcode 15+** (App Store에서 무료 설치)
- **Supabase 계정** (https://supabase.com - 무료)
- **Metals API 키** (https://metals-api.com - 무료 가입)

---

## 2단계: Supabase 설정

### 2-1. 프로젝트 생성
1. https://supabase.com 접속 → 회원가입/로그인
2. "New Project" 클릭
3. 프로젝트 이름: `MetalPriceTracker`
4. 데이터베이스 비밀번호 설정 (안전한 곳에 보관)
5. Region: Northeast Asia (ap-northeast-1) 선택
6. "Create new project" 클릭

### 2-2. 데이터베이스 테이블 생성
1. Supabase 대시보드 → **SQL Editor** 클릭
2. `supabase/migrations/001_create_tables.sql` 파일 내용을 복사하여 실행
3. **Table Editor**에서 metals, daily_prices, price_alerts 테이블이 생성되었는지 확인

### 2-3. Edge Function 배포
1. Supabase CLI 설치:
   ```bash
   npm install -g supabase
   ```
2. 로그인:
   ```bash
   supabase login
   ```
3. 프로젝트 연결:
   ```bash
   cd MetalPriceTracker
   supabase init
   supabase link --project-ref YOUR_PROJECT_REF
   ```
4. 환경변수 설정:
   ```bash
   supabase secrets set METALS_API_KEY=your_metals_api_key
   ```
5. Edge Function 배포:
   ```bash
   supabase functions deploy fetch-metal-prices
   ```

### 2-4. Cron 스케줄 설정
1. Supabase 대시보드 → **Database** → **Extensions**
2. `pg_cron`과 `pg_net` 확장 활성화
3. **SQL Editor**에서 `002_setup_cron.sql` 실행
   - `YOUR_PROJECT_REF`를 실제 프로젝트 참조 ID로 교체
   - `YOUR_SUPABASE_ANON_KEY`를 실제 Anon Key로 교체

### 2-5. API 키 확인
- Supabase 대시보드 → **Settings** → **API**
- **Project URL**: `https://xxx.supabase.co`
- **anon public key**: `eyJ...` (길은 문자열)
- 이 두 값을 iOS 앱 코드에서 사용합니다

---

## 3단계: Metals API 설정

1. https://metals-api.com 접속 → 무료 가입
2. 대시보드에서 **API Key** 복사
3. 무료 플랜: 월 50회 요청 (매일 1회 × 30일 = 충분)

### API 테스트
```bash
curl "https://metals-api.com/api/latest?access_key=YOUR_API_KEY&base=USD&symbols=LME-CU,LME-AL"
```

---

## 4단계: Xcode 프로젝트 설정 (Mac에서)

### 4-1. 새 프로젝트 생성
1. Xcode → File → New → Project
2. **App** 선택 → Next
3. Product Name: `MetalPriceTracker`
4. Interface: **SwiftUI**
5. Language: **Swift**
6. Storage: **None**
7. Create

### 4-2. Supabase SDK 추가
1. File → Add Package Dependencies
2. 검색: `https://github.com/supabase/supabase-swift`
3. 버전: "Up to Next Major Version"
4. Add Package

### 4-3. 소스 파일 추가
이 프로젝트의 `iOS/MetalPriceTracker/` 폴더 안의 모든 Swift 파일을
Xcode 프로젝트에 드래그하여 추가합니다.

### 4-4. Supabase 연결 정보 수정
`Services/SupabaseService.swift` 파일에서:
```swift
private let client = SupabaseClient(
    supabaseURL: URL(string: "https://YOUR_PROJECT_REF.supabase.co")!,
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```
→ 2단계에서 확인한 실제 URL과 Key로 교체

### 4-5. 빌드 및 실행
1. 상단에서 시뮬레이터 선택 (iPhone 15 Pro 등)
2. Cmd + R 으로 빌드 및 실행

---

## 5단계: 동작 확인

### Edge Function 테스트 (수동 실행)
```bash
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-metal-prices \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json"
```

### 데이터 확인
- Supabase 대시보드 → Table Editor → daily_prices 테이블에 데이터가 쌓이는지 확인

### iOS 앱 확인
- 앱 실행 → 대시보드에 시세가 표시되는지 확인
- 금속 카드 탭 → 차트가 표시되는지 확인
- 비교 탭 → 금속 선택 후 비교 차트 확인
- 알림 탭 → 알림 생성 테스트

---

## 프로젝트 파일 구조

```
MetalPriceTracker/
├── SETUP_GUIDE.md              ← 이 파일
├── supabase/
│   ├── migrations/
│   │   ├── 001_create_tables.sql    ← DB 스키마
│   │   └── 002_setup_cron.sql       ← 자동 수집 스케줄
│   └── functions/
│       └── fetch-metal-prices/
│           └── index.ts              ← 시세 수집 함수
└── iOS/
    └── MetalPriceTracker/
        ├── App/
        │   ├── MetalPriceTrackerApp.swift
        │   └── ContentView.swift        ← 탭 네비게이션
        ├── Models/
        │   ├── Metal.swift
        │   ├── DailyPrice.swift
        │   ├── PriceAlert.swift
        │   └── DateRange.swift
        ├── ViewModels/
        │   ├── DashboardViewModel.swift
        │   ├── ChartViewModel.swift
        │   ├── CompareViewModel.swift
        │   └── AlertViewModel.swift
        ├── Views/
        │   ├── Dashboard/
        │   │   ├── DashboardView.swift  ← 메인 대시보드
        │   │   └── MetalCardView.swift
        │   ├── Chart/
        │   │   └── PriceChartView.swift ← 라인/캔들 차트
        │   ├── Compare/
        │   │   └── CompareView.swift    ← 비교 분석
        │   ├── Alert/
        │   │   └── AlertSettingView.swift← 알림 설정
        │   └── Common/
        │       └── LoadingView.swift
        ├── Services/
        │   ├── SupabaseService.swift    ← API 통신
        │   └── NotificationService.swift← 알림
        └── Utilities/
            ├── ColorExtension.swift
            └── DateFormatExtension.swift
```

---

## 문제 해결 (FAQ)

### Q: Edge Function이 실행되지 않아요
- Supabase 대시보드 → Edge Functions → Logs에서 에러 확인
- METALS_API_KEY 환경변수가 올바르게 설정되었는지 확인

### Q: 앱에서 데이터가 안 보여요
- SupabaseService.swift의 URL과 Key가 올바른지 확인
- Supabase Table Editor에서 daily_prices에 데이터가 있는지 확인
- Edge Function을 수동으로 한 번 실행해보세요

### Q: 차트가 비어있어요
- 최소 2일 이상의 데이터가 있어야 차트가 의미있게 표시됩니다
- Edge Function을 여러 번 수동 실행하거나 기다려주세요

### Q: Metals API 무료 한도가 부족해요
- metalpriceapi.com (월 100회) 등 대안 API를 사용할 수 있습니다
- API URL과 응답 형식에 맞게 Edge Function 수정 필요
