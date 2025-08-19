# 자동 슬롯 조정 스크립트
def optimize_slot_allocation():
    # 지난 7일간 사용 패턴 분석
    usage_data = analyze_slot_usage_pattern()
    
    # 사용률이 30% 미만인 시간대 식별
    low_usage_periods = identify_low_usage_periods(usage_data)
    
    # 해당 시간대에 슬롯 감소
    for period in low_usage_periods:
        schedule_slot_reduction(period)