# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a BigQuery workbook collection containing comprehensive documentation and practical examples for BigQuery features in Korean. The repository contains:

- **Documentation**: 26+ markdown files covering BigQuery topics like slots, partitioning, materialized views, ML, JSON processing, data governance, security, and performance optimization
- **Practical Examples**: Two main example directories with SQL scripts, shell commands, Python automation, and YAML configurations

## Architecture

### Documentation Structure
- Root-level markdown files: Comprehensive guides on specific BigQuery features
- `슬롯 예제/` (Slot Examples): 23 files demonstrating BigQuery slot management
- `파티션 예제/` (Partition Examples): 11 files showing partitioning strategies

### File Types and Purposes
- **Markdown files (.md)**: Theoretical documentation and concept explanations
- **SQL files (.sql)**: Query examples and table creation scripts
- **Shell scripts (.sh)**: BigQuery CLI commands and automation scripts
- **Python files (.py)**: Advanced automation for slot management and optimization
- **YAML files (.yaml)**: Monitoring and dashboard configurations
- **CSV/JSON files**: Sample data for examples

## Common Operations

### Working with BigQuery CLI
Examples use the `bq` command-line tool for:
- Creating reservations: `bq mk --reservation --slots=100 my-reservation`
- Creating partitioned tables: `bq mk --table --time_partitioning_field=date --time_partitioning_type=DAY`
- Loading data: `bq load --source_format=CSV dataset.table data.csv`
- Running queries: `bq query --use_legacy_sql=false "SELECT * FROM dataset.table"`

### Python Integration
The Python scripts use Google Cloud libraries:
- `google.cloud.bigquery_reservation_v1` for slot management
- `google.cloud.monitoring_v3` for usage monitoring
- Automated slot scaling based on usage metrics

### Key Topics Covered
- **Performance**: Slot management, partitioning, clustering, query optimization
- **Cost Control**: Scan cost optimization, slot reservations, usage monitoring
- **Data Management**: External tables, streaming, materialized views, data governance
- **Advanced Features**: ML integration, JSON processing, geospatial functions, window functions
- **Security**: Access controls, data governance, security management

## Development Notes

- All documentation is in Korean
- Examples assume Google Cloud project setup with BigQuery enabled
- Scripts reference placeholder values (PROJECT_ID, dataset names) that need customization
- SQL examples follow BigQuery standard SQL syntax
- Shell scripts are designed for Unix-like environments