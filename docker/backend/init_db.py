import os
from datetime import datetime
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker

DB_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(DB_DIR, "archive.db")
DATABASE_URL = f"sqlite:///{DB_FILE}"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class MediaItem(Base):
    __tablename__ = "media_items"
    id = Column(Integer, primary_key=True, index=True)
    file_name = Column(String, index=True)
    file_type = Column(String)
    file_ext = Column(String)
    access_url = Column(String)
    file_size_kb = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)

def init_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    # Check if we already have data
    if db.query(MediaItem).count() > 0:
        print("Database already initialized.")
        db.close()
        return

    # Mock Data matching what we had in frontend API (MIT 6.0001 course)
    mock_images = [
        {"file_name": "lec01_slide01_welcome.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec01_slide01_welcome.png", "file_size_kb": 312, "created_at": "2026-02-24T10:00:00Z"},
        {"file_name": "lec01_slide03_goals.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec01_slide03_goals.png", "file_size_kb": 485, "created_at": "2026-02-24T10:05:00Z"},
        {"file_name": "lec01_slide11_numerical_example.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec01_slide11_numerical_example.png", "file_size_kb": 445, "created_at": "2026-02-24T10:11:00Z"},
        {"file_name": "lec01_slide15_declarative_knowledge.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec01_slide15_declarative_knowledge.png", "file_size_kb": 398, "created_at": "2026-02-24T10:15:00Z"},
        {"file_name": "lec01_slide16_imperative_knowledge.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec01_slide16_imperative_knowledge.png", "file_size_kb": 412, "created_at": "2026-02-24T10:16:00Z"},
        {"file_name": "lec02_slide05_bindings.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec02_slide05_bindings.png", "file_size_kb": 356, "created_at": "2026-02-25T09:00:00Z"},
        {"file_name": "lec02_slide12_strings.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec02_slide12_strings.png", "file_size_kb": 402, "created_at": "2026-02-25T09:15:00Z"},
        {"file_name": "lec03_slide08_iteration.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec03_slide08_iteration.png", "file_size_kb": 478, "created_at": "2026-02-26T14:30:00Z"},
        {"file_name": "lec03_slide14_for_loops.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec03_slide14_for_loops.png", "file_size_kb": 421, "created_at": "2026-02-26T14:45:00Z"},
        {"file_name": "pset1_ps1a.png", "file_type": "image", "file_ext": "png", "access_url": "/images/pset1_ps1a.png", "file_size_kb": 654, "created_at": "2026-02-27T08:00:00Z"},
        {"file_name": "lec01_slide18_aspects_of_languages.png", "file_type": "image", "file_ext": "png", "access_url": "/images/lec01_slide18_aspects_of_languages.png", "file_size_kb": 482, "created_at": "2026-02-27T10:25:00Z"},
        {"file_name": "pset3_document_distance.png", "file_type": "image", "file_ext": "png", "access_url": "/images/pset3_document_distance.png", "file_size_kb": 745, "created_at": "2026-02-27T11:00:00Z"},
    ]
    
    mock_docs = [
        {"file_name": "2024年春季项目总结报告.pdf", "file_type": "document", "file_ext": "pdf", "access_url": "/docs/2024_spring_report.pdf", "file_size_kb": 4502, "created_at": "2026-02-22T09:12:00Z"},
        {"file_name": "第一季度财务审计报表.xlsx", "file_type": "document", "file_ext": "xlsx", "access_url": "/docs/q1_financial_audit.xlsx", "file_size_kb": 1240, "created_at": "2026-02-20T14:30:00Z"},
        {"file_name": "产品需求文档_V2.1.docx", "file_type": "document", "file_ext": "docx", "access_url": "/docs/prd_v2.1.docx", "file_size_kb": 358, "created_at": "2026-02-18T11:45:00Z"},
        {"file_name": "关于加强网络安全的通知.pdf", "file_type": "document", "file_ext": "pdf", "access_url": "/docs/security_notice.pdf", "file_size_kb": 189, "created_at": "2026-02-15T08:20:00Z"},
        {"file_name": "员工入职培训手册_最终版.pdf", "file_type": "document", "file_ext": "pdf", "access_url": "/docs/onboarding_manual.pdf", "file_size_kb": 8900, "created_at": "2026-02-10T16:00:00Z"},
        {"file_name": "客户对接沟通记录_张总.docx", "file_type": "document", "file_ext": "docx", "access_url": "/docs/client_meeting_zhang.docx", "file_size_kb": 45, "created_at": "2026-02-05T10:15:00Z"},
        {"file_name": "2023年度运营数据盘点.xlsx", "file_type": "document", "file_ext": "xlsx", "access_url": "/docs/2023_operations_data.xlsx", "file_size_kb": 4560, "created_at": "2026-01-20T13:40:00Z"},
        {"file_name": "技术部团建活动策划方案.docx", "file_type": "document", "file_ext": "docx", "access_url": "/docs/team_building_plan.docx", "file_size_kb": 120, "created_at": "2026-01-15T09:00:00Z"},
        {"file_name": "服务器架构升级评估.pdf", "file_type": "document", "file_ext": "pdf", "access_url": "/docs/server_arch_upgrade.pdf", "file_size_kb": 3400, "created_at": "2026-01-10T11:20:00Z"},
        {"file_name": "竞品分析调研表格.xlsx", "file_type": "document", "file_ext": "xlsx", "access_url": "/docs/competitor_analysis.xlsx", "file_size_kb": 890, "created_at": "2026-01-05T15:10:00Z"},
    ]

    for item in mock_images + mock_docs:
        db_item = MediaItem(
            file_name=item["file_name"],
            file_type=item["file_type"],
            file_ext=item["file_ext"],
            access_url=item["access_url"],
            file_size_kb=item["file_size_kb"],
            created_at=datetime.fromisoformat(item["created_at"].replace("Z", "+00:00")).replace(tzinfo=None)
        )
        db.add(db_item)
    
    db.commit()
    db.close()
    print("Database initialized and populated with mock data.")

if __name__ == "__main__":
    init_db()
