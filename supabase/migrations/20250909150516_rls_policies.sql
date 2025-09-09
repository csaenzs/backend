-- Row Level Security Policies Migration
-- Author: Restaurant Pro
-- Date: 2025-01-09

-- Enable RLS on all tables
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.third_parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_configs ENABLE ROW LEVEL SECURITY;

-- ====================================
-- HELPER FUNCTIONS
-- ====================================

-- Function to check if user is superadmin
CREATE OR REPLACE FUNCTION is_superadmin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (auth.jwt() ->> 'app_metadata')::jsonb ->> 'role' = 'superadmin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current user's client_id
CREATE OR REPLACE FUNCTION get_current_client_id()
RETURNS UUID AS $$
DECLARE
  client_uuid UUID;
BEGIN
  -- If superadmin and not impersonating, return NULL (can access all data)
  IF is_superadmin() AND NOT ((auth.jwt() ->> 'app_metadata')::jsonb ->> 'is_impersonating')::boolean THEN
    RETURN NULL;
  END IF;
  
  -- Get client_id from clients table based on user_id
  SELECT id INTO client_uuid
  FROM public.clients
  WHERE user_id = auth.uid();
  
  RETURN client_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================
-- CLIENTS TABLE POLICIES
-- ====================================

-- Superadmins can do everything with clients
CREATE POLICY "superadmin_clients_all" ON public.clients
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

-- Users can only see their own client record
CREATE POLICY "clients_own_record" ON public.clients
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() AND NOT is_superadmin());

-- ====================================
-- COMPANY_INFO TABLE POLICIES
-- ====================================

-- Superadmins can access all company info
CREATE POLICY "superadmin_company_info_all" ON public.company_info
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

-- Clients can only access their own company info
CREATE POLICY "company_info_client_access" ON public.company_info
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- LOCATIONS TABLE POLICIES
-- ====================================

CREATE POLICY "superadmin_locations_all" ON public.locations
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "locations_client_access" ON public.locations
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- PRODUCTS POLICIES
-- ====================================

CREATE POLICY "superadmin_products_all" ON public.products
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "products_client_access" ON public.products
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- PRODUCT CATEGORIES POLICIES
-- ====================================

CREATE POLICY "superadmin_product_categories_all" ON public.product_categories
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "product_categories_client_access" ON public.product_categories
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- INVENTORY MOVEMENTS POLICIES
-- ====================================

CREATE POLICY "superadmin_inventory_movements_all" ON public.inventory_movements
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "inventory_movements_client_access" ON public.inventory_movements
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- TABLES POLICIES
-- ====================================

CREATE POLICY "superadmin_tables_all" ON public.tables
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "tables_client_access" ON public.tables
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- THIRD PARTIES POLICIES
-- ====================================

CREATE POLICY "superadmin_third_parties_all" ON public.third_parties
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "third_parties_client_access" ON public.third_parties
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- ORDERS POLICIES
-- ====================================

CREATE POLICY "superadmin_orders_all" ON public.orders
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "orders_client_access" ON public.orders
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- ORDER ITEMS POLICIES
-- ====================================

CREATE POLICY "superadmin_order_items_all" ON public.order_items
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "order_items_client_access" ON public.order_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders 
      WHERE orders.id = order_items.order_id 
      AND orders.client_id = get_current_client_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders 
      WHERE orders.id = order_items.order_id 
      AND orders.client_id = get_current_client_id()
    )
  );

-- ====================================
-- INVOICES POLICIES
-- ====================================

CREATE POLICY "superadmin_invoices_all" ON public.invoices
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "invoices_client_access" ON public.invoices
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- INVOICE ITEMS POLICIES
-- ====================================

CREATE POLICY "superadmin_invoice_items_all" ON public.invoice_items
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "invoice_items_client_access" ON public.invoice_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.invoices 
      WHERE invoices.id = invoice_items.invoice_id 
      AND invoices.client_id = get_current_client_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.invoices 
      WHERE invoices.id = invoice_items.invoice_id 
      AND invoices.client_id = get_current_client_id()
    )
  );

-- ====================================
-- PAYMENTS POLICIES
-- ====================================

CREATE POLICY "superadmin_payments_all" ON public.payments
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "payments_client_access" ON public.payments
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- PURCHASES POLICIES
-- ====================================

CREATE POLICY "superadmin_purchases_all" ON public.purchases
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "purchases_client_access" ON public.purchases
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- PURCHASE ITEMS POLICIES
-- ====================================

CREATE POLICY "superadmin_purchase_items_all" ON public.purchase_items
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "purchase_items_client_access" ON public.purchase_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.purchases 
      WHERE purchases.id = purchase_items.purchase_id 
      AND purchases.client_id = get_current_client_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.purchases 
      WHERE purchases.id = purchase_items.purchase_id 
      AND purchases.client_id = get_current_client_id()
    )
  );

-- ====================================
-- EXPENSES POLICIES
-- ====================================

CREATE POLICY "superadmin_expenses_all" ON public.expenses
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "expenses_client_access" ON public.expenses
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- EMPLOYEES POLICIES
-- ====================================

CREATE POLICY "superadmin_employees_all" ON public.employees
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "employees_client_access" ON public.employees
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- PERFORMANCE EVALUATIONS POLICIES
-- ====================================

CREATE POLICY "superadmin_performance_evaluations_all" ON public.performance_evaluations
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "performance_evaluations_client_access" ON public.performance_evaluations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.employees 
      WHERE employees.id = performance_evaluations.employee_id 
      AND employees.client_id = get_current_client_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.employees 
      WHERE employees.id = performance_evaluations.employee_id 
      AND employees.client_id = get_current_client_id()
    )
  );

-- ====================================
-- PAYROLL POLICIES
-- ====================================

CREATE POLICY "superadmin_payroll_runs_all" ON public.payroll_runs
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "payroll_runs_client_access" ON public.payroll_runs
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

CREATE POLICY "superadmin_payroll_details_all" ON public.payroll_details
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "payroll_details_client_access" ON public.payroll_details
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.payroll_runs 
      WHERE payroll_runs.id = payroll_details.payroll_run_id 
      AND payroll_runs.client_id = get_current_client_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.payroll_runs 
      WHERE payroll_runs.id = payroll_details.payroll_run_id 
      AND payroll_runs.client_id = get_current_client_id()
    )
  );

-- ====================================
-- BANK ACCOUNTS POLICIES
-- ====================================

CREATE POLICY "superadmin_bank_accounts_all" ON public.bank_accounts
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "bank_accounts_client_access" ON public.bank_accounts
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- BANK TRANSACTIONS POLICIES
-- ====================================

CREATE POLICY "superadmin_bank_transactions_all" ON public.bank_transactions
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "bank_transactions_client_access" ON public.bank_transactions
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- TAX CONFIGS POLICIES
-- ====================================

CREATE POLICY "superadmin_tax_configs_all" ON public.tax_configs
  FOR ALL
  TO authenticated
  USING (is_superadmin())
  WITH CHECK (is_superadmin());

CREATE POLICY "tax_configs_client_access" ON public.tax_configs
  FOR ALL
  TO authenticated
  USING (client_id = get_current_client_id())
  WITH CHECK (client_id = get_current_client_id());

-- ====================================
-- GRANT PERMISSIONS
-- ====================================

-- Grant usage on all tables to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions for functions
GRANT EXECUTE ON FUNCTION is_superadmin() TO authenticated;
GRANT EXECUTE ON FUNCTION get_current_client_id() TO authenticated;