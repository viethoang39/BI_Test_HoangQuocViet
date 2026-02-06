# BI Test - Hoang Quoc Viet

## 1. Giới thiệu
File này là kết quả thực hiện cho bài test **BI Toolset - TAKE-HOME ASSIGNMENT**. 
Nội dung bài làm tập trung vào việc phân tích dữ liệu trải nghiệm khách hàng (NPS) và đơn hàng bị hủy, từ đó xây dựng các giải pháp tự động hóa và báo cáo quản trị (Dashboard) nhằm tối ưu vận hành và nâng cao chất lượng dịch vụ.

## 2. Tech Stack sử dụng
Dựa trên yêu cầu, tech stack được lựa chọn để thực hiện bài test bao gồm:

*   **Database Engine**: **Databricks (SQL)** (Đây là công cụ xử lý chính).
*   **Ngôn ngữ**:
    *   **SQL**: Sử dụng cho phần lớn các tác vụ: làm sạch dữ liệu (Data Cleaning), chuẩn hóa văn bản (Text normalization), tính toán chỉ số (Metrics calculation) và phát hiện bất thường (Anomaly detection).
    *   **Python (Jupyter Notebook)**: Sử dụng cho task trích xuất từ khóa (Keyword Extraction) và kiểm tra kết quả Visualizations.
*   **Design & Automation**:
    *   **Workflow Design**: Mô hình hóa quy trình tự động trên lý thuyết (dựa trên Power Automate/n8n).
    *   **Dashboard Mockup**: Thiết kế layout báo cáo cho Power BI.

## 3. Cấu trúc thư mục
File được tổ chức thành các thư mục tương ứng với từng phần yêu cầu của đề bài:

```
/BI_Test_HoangQuocViet/
│
├── README.md                   # File hiện tại: Tóm tắt approach & tech stack
│
├── Part1_SQL/                  # PHẦN 1: ANALYST
│   ├── query_1_1.sql           # SQL: Sentiment Classification (Clean & Classify)
│   ├── query_1_2_*.sql         # SQL: NPS Score Analysis & Ranking
│   ├── Top10_Keywords.ipynb    # Python: Trích xuất Top 10 Keywords từ comment
│   └── *_result.ipynb          # (Optional) Notebook kiểm tra kết quả query
│
├── Part2_Automation/           # PHẦN 2: AUTOMATION
│   ├── Flow1_Weekly NPS Alert.md   # Design: Luồng cảnh báo NPS hàng tuần
│   ├── Flow1_Weekly NPS Alert.png  # Diagram: Sơ đồ luồng 1
│   ├── Flow2_Auto-tagging CRM.md   # Design: Luồng tự động gắn tag CRM
│   └── Flow2_Auto-tagging CRM.png  # Diagram: Sơ đồ luồng 2
│
└── Part3_Insights/             # PHẦN 3: BI INSIGHTS
    ├── Business_Recommendations.md # Đề xuất Metrics, Early Warning Signals & SQL
    └── dashboard_proposal.png      # Hình ảnh phác thảo Dashboard Layout bằng Power BI
```

## 4. Chi tiết Approach (Phương pháp tiếp cận)

### Phần 1: Analyst (SQL & Python)
*   **1.1 Sentiment Classification**:
    *   **Vấn đề**: Dữ liệu comment chứa nhiều teencode (vd: "ko", "khum", "tot").
    *   **Giải pháp**: Sử dụng hàm `REGEXP_REPLACE` trong SQL để chuẩn hóa các biến thể teencode về tiếng Việt chuẩn trước khi phân loại. Cách tiếp cận này giúp xử lý nhanh ngay trong Database mà không cần mang ra ngoài script Python phức tạp.
*   **1.2 NPS Score Analysis**:
    *   Sử dụng SQL để tính toán các chỉ số thống kê cơ bản (`AVG`, `MEDIAN` - nếu DB hỗ trợ hoặc dùng workaround, `COUNT`).
    *   Xác định Top 3 models có điểm thấp nhất để khoanh vùng vấn đề về thiết bị.
*   **1.3 Keyword Extraction**:
    *   Sử dụng **Python** (`sklearn` / `Counter`) trong Notebook để tách từ và đếm tần suất xuất hiện (Frequency Count). Đây là giải pháp linh hoạt hơn SQL thuần túy khi xử lý bài toán tách từ khóa tự do.

### Phần 2: Automation & Workflow
Xây dựng 2 quy trình tự động hóa nhằm chuyển đổi từ "Insight" sang "Action":

**1. Weekly NPS Alert (Cảnh báo chất lượng định kỳ)**
*   **Mục tiêu**: Hệ thống tự động quét DB hàng tuần và gửi email cảnh báo kèm danh sách comment nếu điểm NPS trung bình của dòng máy nào đó < 6.
*   **Tech Stack**:
    *   **Orchestrator**: **Microsoft Power Automate** (Cloud Flow).
    *   **Trigger**: Scheduled Cloud Flow (Recurrence: Weekly).
    *   **Action Nodes**: 
        *   *Databricks Connector*: Thực thi SQL query để lọc bad comments (WHERE dateid = last week).
        *   *Data Operation*: Chuyển đổi JSON sang CSV.
        *   *Office 365 Outlook*: Gửi email tự động tới Sales/Product Team.

**2. Auto-tagging CRM (Tự động phân loại lý do hủy)**
*   **Mục tiêu**: Tối ưu vận hành bằng cách tự động đọc lý do hủy đơn mới, sử dụng AI để gắn nhãn (Tag) và cập nhật ngược lại vào hệ thống CRM.
*   **Tech Stack**:
    *   **Orchestrator**: **n8n** (Workflow Automation Tool).
    *   **AI Engine**: **Google Gemini AI** (thông qua n8n AI Node) để phân tích sentiment và extract tag từ text tiếng Việt.
    *   **Integration**:
        *   *HTTP Request (GET)*: Gọi API Databricks SQL để lấy đơn hủy mới trong ngày.
        *   *HTTP Request (POST)*: Gọi API CRM để update tag cho từng đơn hàng (Loop) (Giả định Backend của CRM là databricks).
        *   *Google Chat/Slack*: Gửi thông báo hoàn tất job.

### Phần 3: BI Insights & Dashboard
*   **Metrics Selection**: Tập trung vào 3 chỉ số cốt lõi: *NPS Score* (Sức khỏe thương hiệu), *Order Cancel Rate* (Hiệu quả vận hành), và *Cancellation Sentiment* (Góc nhìn khách hàng).
*   **Early Warning Signals (SQL Logic)**: 
    *   Sử dụng **Window Functions** (`PERCENTILE_CONT`, `OVER`) để tính toán ngưỡng cảnh báo động (Dynamic Thresholds) dựa trên lịch sử theo ngày (Rolling Window).
    *   Phát hiện bất thường (Anomaly) khi chỉ số hiện tại vượt quá các ngưỡng phân vị (P5 hoặc P95).
*   **Dashboard**: Thiết kế theo tư duy **"Overview to Detail"**, giúp cấp quản lý (Director) nắm bắt nhanh tình hình và cho phép drill-down để tìm nguyên nhân gốc rễ (Root Cause Analysis).
