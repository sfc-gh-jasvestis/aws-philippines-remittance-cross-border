-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Cross-Border Remittance Analytics & Corridor Intelligence
-- ============================================================================
USE DATABASE REMITTANCE_OPS;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.REMITTANCE_INTELLIGENCE_AGENT
  COMMENT = 'Cross-Border Remittance Analytics & Corridor Intelligence AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'REMITTANCE_OPS.APP.REMITTANCE_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'REMITTANCE_OPS.SEARCH.BSP_REGULATORY_SEARCH', TOOL_DESCRIPTION => 'Search documents for Remittances & Fintech information')
  )
  SYSTEM_PROMPT = 'You are the Remittance Intelligence Agent for a Philippine remittance company processing 2.4M transactions across 210 corridors, serving 10M+ OFW families.';
