-- =====================================================
-- 📊 COMPREHENSIVE ANALYTICS FUNCTION
-- =====================================================
-- This function provides in-depth analytics for orders, revenue, customers, and more
-- Usage: SELECT * FROM get_comprehensive_analytics('2025-01-01'::TIMESTAMPTZ, '2025-01-31'::TIMESTAMPTZ, NULL);
-- For cafe-specific: SELECT * FROM get_comprehensive_analytics('2025-01-01'::TIMESTAMPTZ, '2025-01-31'::TIMESTAMPTZ, 'cafe-uuid-here');
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_comprehensive_analytics(
    p_start_date TIMESTAMPTZ DEFAULT (NOW() - INTERVAL '30 days'),
    p_end_date TIMESTAMPTZ DEFAULT NOW(),
    p_cafe_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        -- ============================================
        -- OVERALL METRICS
        -- ============================================
        'overall_metrics', json_build_object(
            'total_orders', (
                SELECT COUNT(*)::INTEGER
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
            ),
            'completed_orders', (
                SELECT COUNT(*)::INTEGER
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'completed'
            ),
            'cancelled_orders', (
                SELECT COUNT(*)::INTEGER
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'cancelled'
            ),
            'pending_orders', (
                SELECT COUNT(*)::INTEGER
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status NOT IN ('completed', 'cancelled')
            ),
            'total_revenue', (
                SELECT COALESCE(SUM(o.total_amount), 0)::DECIMAL(10,2)
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'completed'
            ),
            'original_revenue', (
                SELECT COALESCE(SUM(COALESCE(o.original_total_amount, o.total_amount)), 0)::DECIMAL(10,2)
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'completed'
            ),
            'total_discount_amount', (
                SELECT COALESCE(SUM(COALESCE(o.discount_amount, 0)), 0)::DECIMAL(10,2)
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'completed'
            ),
            'average_order_value', (
                SELECT COALESCE(AVG(o.total_amount), 0)::DECIMAL(10,2)
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'completed'
            ),
            'total_customers', (
                SELECT COUNT(DISTINCT COALESCE(o.user_id::TEXT, o.phone_number))::INTEGER
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
            ),
            'returning_customers', (
                SELECT COUNT(DISTINCT customer_id)::INTEGER
                FROM (
                    SELECT COALESCE(o.user_id::TEXT, o.phone_number) as customer_id
                    FROM public.orders o
                    WHERE o.created_at >= p_start_date 
                        AND o.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    GROUP BY customer_id
                    HAVING COUNT(*) > 1
                ) returning_customers
            ),
            'new_customers', (
                SELECT COUNT(DISTINCT customer_id)::INTEGER
                FROM (
                    SELECT COALESCE(o.user_id::TEXT, o.phone_number) as customer_id
                    FROM public.orders o
                    WHERE o.created_at >= p_start_date 
                        AND o.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    GROUP BY customer_id
                    HAVING COUNT(*) = 1
                ) new_customers
            ),
            'completion_rate', (
                SELECT CASE 
                    WHEN COUNT(*) > 0 THEN 
                        ROUND((COUNT(*) FILTER (WHERE o.status = 'completed')::DECIMAL / COUNT(*)::DECIMAL) * 100, 2)
                    ELSE 0
                END
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
            ),
            'cancellation_rate', (
                SELECT CASE 
                    WHEN COUNT(*) > 0 THEN 
                        ROUND((COUNT(*) FILTER (WHERE o.status = 'cancelled')::DECIMAL / COUNT(*)::DECIMAL) * 100, 2)
                    ELSE 0
                END
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
            ),
            'total_points_earned', (
                SELECT COALESCE(SUM(o.points_earned), 0)::INTEGER
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'completed'
            )
        ),

        -- ============================================
        -- ORDERS BY STATUS
        -- ============================================
        'orders_by_status', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'status', status,
                    'count', count,
                    'percentage', ROUND((count::DECIMAL / NULLIF(total, 0)::DECIMAL) * 100, 2)
                ) ORDER BY count DESC
            ), '[]'::json)
            FROM (
                SELECT 
                    o.status,
                    COUNT(*)::INTEGER as count,
                    (SELECT COUNT(*) FROM public.orders o2 
                     WHERE o2.created_at >= p_start_date 
                        AND o2.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o2.cafe_id = p_cafe_id)) as total
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                GROUP BY o.status
            ) status_counts
        ),

        -- ============================================
        -- ORDERS BY PAYMENT METHOD
        -- ============================================
        'orders_by_payment_method', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'payment_method', COALESCE(payment_method, 'unknown'),
                    'count', count,
                    'revenue', revenue,
                    'percentage', ROUND((count::DECIMAL / NULLIF(total, 0)::DECIMAL) * 100, 2)
                ) ORDER BY revenue DESC
            ), '[]'::json)
            FROM (
                SELECT 
                    o.payment_method,
                    COUNT(*)::INTEGER as count,
                    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as revenue,
                    (SELECT COUNT(*) FROM public.orders o2 
                     WHERE o2.created_at >= p_start_date 
                        AND o2.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o2.cafe_id = p_cafe_id)) as total
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                GROUP BY o.payment_method
            ) payment_counts
        ),

        -- ============================================
        -- ORDERS BY ORDER TYPE
        -- ============================================
        'orders_by_order_type', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'order_type', order_type,
                    'count', count,
                    'revenue', revenue,
                    'percentage', ROUND((count::DECIMAL / NULLIF(total, 0)::DECIMAL) * 100, 2)
                ) ORDER BY revenue DESC
            ), '[]'::json)
            FROM (
                SELECT 
                    order_type,
                    COUNT(*)::INTEGER as count,
                    COALESCE(SUM(total_amount) FILTER (WHERE status = 'completed'), 0)::DECIMAL(10,2) as revenue,
                    (SELECT COUNT(*) FROM public.orders o2 
                     WHERE o2.created_at >= p_start_date 
                        AND o2.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o2.cafe_id = p_cafe_id)) as total
                FROM (
                    SELECT 
                        o.id,
                        o.status,
                        o.total_amount,
                        COALESCE(o.order_type, CASE 
                            WHEN o.delivery_block::TEXT = 'DINE_IN' OR o.table_number IS NOT NULL THEN 'table_order'
                            WHEN o.delivery_block::TEXT = 'TAKEAWAY' THEN 'takeaway'
                            ELSE 'delivery'
                        END) as order_type
                    FROM public.orders o
                    WHERE o.created_at >= p_start_date 
                        AND o.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                ) orders_with_type
                GROUP BY order_type
            ) type_counts
        ),

        -- ============================================
        -- REVENUE BY CAFE
        -- ============================================
        'revenue_by_cafe', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'cafe_id', cafe_id,
                    'cafe_name', cafe_name,
                    'total_orders', total_orders,
                    'completed_orders', completed_orders,
                    'total_revenue', total_revenue,
                    'average_order_value', average_order_value,
                    'percentage_of_total', ROUND((total_revenue::DECIMAL / NULLIF(grand_total, 0)::DECIMAL) * 100, 2)
                ) ORDER BY total_revenue DESC
            ), '[]'::json)
            FROM (
                SELECT 
                    c.id as cafe_id,
                    c.name as cafe_name,
                    COUNT(*)::INTEGER as total_orders,
                    COUNT(*) FILTER (WHERE o.status = 'completed')::INTEGER as completed_orders,
                    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as total_revenue,
                    COALESCE(AVG(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as average_order_value,
                    (SELECT COALESCE(SUM(o2.total_amount), 0) FROM public.orders o2 
                     WHERE o2.created_at >= p_start_date 
                        AND o2.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o2.cafe_id = p_cafe_id)
                        AND o2.status = 'completed') as grand_total
                FROM public.orders o
                JOIN public.cafes c ON c.id = o.cafe_id
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                GROUP BY c.id, c.name
            ) cafe_stats
        ),

        -- ============================================
        -- TOP SELLING ITEMS
        -- ============================================
        'top_selling_items', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'item_id', item_id,
                    'item_name', item_name,
                    'category', category,
                    'total_quantity', total_quantity,
                    'total_revenue', total_revenue,
                    'order_count', order_count,
                    'average_price', average_price
                ) ORDER BY total_revenue DESC
            ), '[]'::json)
            FROM (
                SELECT 
                    mi.id as item_id,
                    mi.name as item_name,
                    mi.category,
                    SUM(oi.quantity)::INTEGER as total_quantity,
                    COALESCE(SUM(oi.total_price) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as total_revenue,
                    COUNT(DISTINCT o.id)::INTEGER as order_count,
                    COALESCE(AVG(oi.unit_price), 0)::DECIMAL(10,2) as average_price
                FROM public.order_items oi
                JOIN public.orders o ON o.id = oi.order_id
                JOIN public.menu_items mi ON mi.id = oi.menu_item_id
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                GROUP BY mi.id, mi.name, mi.category
                ORDER BY total_revenue DESC
                LIMIT 20
            ) item_stats
        ),

        -- ============================================
        -- TOP CUSTOMERS
        -- ============================================
        'top_customers', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'customer_id', customer_id,
                    'customer_name', customer_name,
                    'phone_number', phone_number,
                    'email', email,
                    'total_orders', total_orders,
                    'total_spent', total_spent,
                    'average_order_value', average_order_value,
                    'last_order_date', last_order_date,
                    'total_points', total_points
                ) ORDER BY total_spent DESC
            ), '[]'::json)
            FROM (
                SELECT 
                    customer_id,
                    customer_name,
                    phone_number,
                    email,
                    COUNT(*)::INTEGER as total_orders,
                    COALESCE(SUM(total_amount) FILTER (WHERE status = 'completed'), 0)::DECIMAL(10,2) as total_spent,
                    COALESCE(AVG(total_amount) FILTER (WHERE status = 'completed'), 0)::DECIMAL(10,2) as average_order_value,
                    MAX(created_at)::TEXT as last_order_date,
                    COALESCE(SUM(points_earned) FILTER (WHERE status = 'completed'), 0)::INTEGER as total_points
                FROM (
                    SELECT 
                        o.id,
                        o.status,
                        o.total_amount,
                        o.created_at,
                        o.points_earned,
                        COALESCE(o.user_id::TEXT, o.phone_number) as customer_id,
                        COALESCE(p.full_name, o.customer_name, 'Unknown') as customer_name,
                        COALESCE(p.phone, o.phone_number) as phone_number,
                        COALESCE(p.email, 'N/A') as email
                    FROM public.orders o
                    LEFT JOIN public.profiles p ON p.id = o.user_id
                    WHERE o.created_at >= p_start_date 
                        AND o.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                ) orders_with_customer
                GROUP BY customer_id, customer_name, phone_number, email
                ORDER BY total_spent DESC
                LIMIT 20
            ) customer_stats
        ),

        -- ============================================
        -- REVENUE BY DAY
        -- ============================================
        'revenue_by_day', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'date', date,
                    'day_name', day_name,
                    'total_orders', total_orders,
                    'completed_orders', completed_orders,
                    'total_revenue', total_revenue,
                    'average_order_value', average_order_value
                ) ORDER BY date
            ), '[]'::json)
            FROM (
                SELECT 
                    DATE(o.created_at)::TEXT as date,
                    TO_CHAR(o.created_at, 'Day') as day_name,
                    COUNT(*)::INTEGER as total_orders,
                    COUNT(*) FILTER (WHERE o.status = 'completed')::INTEGER as completed_orders,
                    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as total_revenue,
                    COALESCE(AVG(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as average_order_value
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                GROUP BY DATE(o.created_at), TO_CHAR(o.created_at, 'Day')
                ORDER BY DATE(o.created_at)
            ) daily_stats
        ),

        -- ============================================
        -- REVENUE BY HOUR
        -- ============================================
        'revenue_by_hour', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'hour', hour,
                    'total_orders', total_orders,
                    'total_revenue', total_revenue,
                    'average_order_value', average_order_value
                ) ORDER BY hour
            ), '[]'::json)
            FROM (
                SELECT 
                    EXTRACT(HOUR FROM o.created_at)::INTEGER as hour,
                    COUNT(*)::INTEGER as total_orders,
                    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as total_revenue,
                    COALESCE(AVG(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as average_order_value
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                GROUP BY EXTRACT(HOUR FROM o.created_at)
                ORDER BY hour
            ) hourly_stats
        ),

        -- ============================================
        -- ORDERS BY DELIVERY BLOCK
        -- ============================================
        'orders_by_delivery_block', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'delivery_block', delivery_block,
                    'count', count,
                    'revenue', revenue,
                    'percentage', ROUND((count::DECIMAL / NULLIF(total, 0)::DECIMAL) * 100, 2)
                ) ORDER BY count DESC
            ), '[]'::json)
            FROM (
                SELECT 
                    o.delivery_block::TEXT as delivery_block,
                    COUNT(*)::INTEGER as count,
                    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as revenue,
                    (SELECT COUNT(*) FROM public.orders o2 
                     WHERE o2.created_at >= p_start_date 
                        AND o2.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o2.cafe_id = p_cafe_id)) as total
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                GROUP BY o.delivery_block
            ) block_counts
        ),

        -- ============================================
        -- OFFER/DISCOUNT USAGE
        -- ============================================
        'offer_usage', json_build_object(
            'total_orders_with_offers', (
                SELECT COUNT(DISTINCT o.id)::INTEGER
                FROM public.orders o
                JOIN public.order_applied_offers oao ON oao.order_id = o.id
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'completed'
            ),
            'total_discount_amount', (
                SELECT COALESCE(SUM(o.discount_amount), 0)::DECIMAL(10,2)
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'completed'
            ),
            'average_discount_per_order', (
                SELECT COALESCE(AVG(o.discount_amount), 0)::DECIMAL(10,2)
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                    AND o.status = 'completed' 
                    AND o.discount_amount > 0
            ),
            'top_offers', (
                SELECT COALESCE(json_agg(
                    json_build_object(
                        'offer_id', offer_id,
                        'offer_name', offer_name,
                        'usage_count', usage_count,
                        'total_discount_amount', total_discount_amount
                    ) ORDER BY usage_count DESC
                ), '[]'::json)
                FROM (
                    SELECT 
                        COALESCE(oao.offer_id::TEXT, 'deleted') as offer_id,
                        COALESCE(oao.offer_name, 'Unknown Offer') as offer_name,
                        COUNT(*)::INTEGER as usage_count,
                        COALESCE(SUM(oao.discount_amount), 0)::DECIMAL(10,2) as total_discount_amount
                    FROM public.order_applied_offers oao
                    JOIN public.orders o ON o.id = oao.order_id
                    WHERE o.created_at >= p_start_date 
                        AND o.created_at <= p_end_date
                        AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
                        AND o.status = 'completed'
                    GROUP BY oao.offer_id, oao.offer_name
                    ORDER BY usage_count DESC
                    LIMIT 10
                ) offer_stats
            )
        ),

        -- ============================================
        -- GROWTH METRICS (vs previous period)
        -- ============================================
        'growth_metrics', (
            WITH current_period AS (
                SELECT 
                    COUNT(*)::INTEGER as orders,
                    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as revenue,
                    COUNT(DISTINCT COALESCE(o.user_id::TEXT, o.phone_number))::INTEGER as customers
                FROM public.orders o
                WHERE o.created_at >= p_start_date 
                    AND o.created_at <= p_end_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
            ),
            previous_period AS (
                SELECT 
                    COUNT(*)::INTEGER as orders,
                    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'completed'), 0)::DECIMAL(10,2) as revenue,
                    COUNT(DISTINCT COALESCE(o.user_id::TEXT, o.phone_number))::INTEGER as customers
                FROM public.orders o
                WHERE o.created_at >= (p_start_date - (p_end_date - p_start_date))
                    AND o.created_at < p_start_date
                    AND (p_cafe_id IS NULL OR o.cafe_id = p_cafe_id)
            )
            SELECT json_build_object(
                'orders_growth', CASE 
                    WHEN prev.orders > 0 THEN 
                        ROUND(((curr.orders::DECIMAL - prev.orders::DECIMAL) / prev.orders::DECIMAL) * 100, 2)
                    ELSE 0
                END,
                'revenue_growth', CASE 
                    WHEN prev.revenue > 0 THEN 
                        ROUND(((curr.revenue - prev.revenue) / prev.revenue) * 100, 2)
                    ELSE 0
                END,
                'customers_growth', CASE 
                    WHEN prev.customers > 0 THEN 
                        ROUND(((curr.customers::DECIMAL - prev.customers::DECIMAL) / prev.customers::DECIMAL) * 100, 2)
                    ELSE 0
                END,
                'current_orders', curr.orders,
                'previous_orders', prev.orders,
                'current_revenue', curr.revenue,
                'previous_revenue', prev.revenue,
                'current_customers', curr.customers,
                'previous_customers', prev.customers
            )
            FROM current_period curr, previous_period prev
        )
    )
    INTO v_result;

    RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_comprehensive_analytics(TIMESTAMPTZ, TIMESTAMPTZ, UUID) TO authenticated, anon;

-- Add comment
COMMENT ON FUNCTION public.get_comprehensive_analytics IS 
'Comprehensive analytics function that returns detailed metrics including:
- Overall metrics (orders, revenue, customers, completion rates)
- Orders by status, payment method, order type, delivery block
- Revenue by cafe, day, hour
- Top selling items and top customers
- Offer/discount usage
- Growth metrics vs previous period
Usage: SELECT * FROM get_comprehensive_analytics(start_date, end_date, cafe_id);
If cafe_id is NULL, returns analytics for all cafes.';
