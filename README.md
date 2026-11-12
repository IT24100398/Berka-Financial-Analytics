
# Banking Transaction Data Warehouse & BI Dashboard

This project uses the **Berka Financial Dataset (PKDD'99 Discovery Challenge)** to design a banking data warehouse and develop interactive Power BI dashboards that help analyse historical banking transactions and identify meaningful business insights.

---

## Project Overview

The main objective is to transform historical banking data into a structured data warehouse and present meaningful information through interactive dashboards to support data-driven business decisions.

## Project Workflow

1. Data Source – Berka Financial Dataset
2. Data Preparation and Loading
3. Data Warehouse Design
4. Star Schema Implementation
5. Data Mart Development
6. Power BI Dashboard Development
7. Business Insights and Recommendations

---

## Data Warehouse Design

The project follows a **Star Schema** design.

### Fact Table
- FactTransaction

### Dimension Tables
- DimDate
- DimAccount
- DimCustomer
- DimDistrict
- DimTransactionType
- DimOperation

---

## Power BI Dashboard

The dashboard consists of three interactive pages.

### 1. Executive Summary

Provides an overview of banking performance through key performance indicators, transaction amounts, monthly performance, transaction types, operations, and district-level activity.

![Executive Summary](Screenshots/03-executive-summary.png)

### 2. Trend Analysis

Explores transaction trends across years, months, transaction types, operations, and regions to identify changes in banking activity over time.

![Trend Analysis](Screenshots/04-trend-analysis.png)

### 3. Interactive Banking Analysis

Allows users to explore banking transactions using filters such as date, customer ID, transaction type, and operation.

![Interactive Banking Analysis](Screenshots/05-interactive-analysis.png)

---

## Project Workflow Diagram

![Project Workflow](Screenshots/02-project-workflow.png)

---

## Business Recommendations

![Recommendations](Screenshots/06-recommendations.png)

---

## Tools and Technologies

- Microsoft SQL Server
- SQL
- Microsoft Power BI
- Data Warehousing
- Dimensional Modelling
- Star Schema
- Data Mart

---

## Learning Outcomes

Through this project, we gained practical experience in:

- Designing and implementing a data warehouse.
- Understanding dimensional modelling and Star Schema architecture.
- Developing SQL queries for data preparation and analysis.
- Creating a Data Mart for reporting.
- Building interactive Power BI dashboards.
- Translating analytical findings into business recommendations.

---

**Academic Project | Data Warehousing & Business Intelligence**
