package db

import (
	"database/sql"
	"time"

	"github.com/darooyar/server/models"
)

// CreatePlan creates a new plan in the database
func CreatePlan(plan *models.PlanCreate) (*models.Plan, error) {
	query := `
		INSERT INTO plans (title, description, price, duration_days, max_uses, plan_type, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, title, description, price, duration_days, max_uses, plan_type, created_at, updated_at`

	now := time.Now()
	var newPlan models.Plan
	err := DB.QueryRow(
		query,
		plan.Title,
		plan.Description,
		plan.Price,
		plan.DurationDays,
		plan.MaxUses,
		plan.PlanType,
		now,
		now,
	).Scan(
		&newPlan.ID,
		&newPlan.Title,
		&newPlan.Description,
		&newPlan.Price,
		&newPlan.DurationDays,
		&newPlan.MaxUses,
		&newPlan.PlanType,
		&newPlan.CreatedAt,
		&newPlan.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &newPlan, nil
}

// GetPlanByID retrieves a plan by ID
func GetPlanByID(id int64) (*models.Plan, error) {
	query := `
		SELECT id, title, description, price, duration_days, max_uses, plan_type, created_at, updated_at
		FROM plans
		WHERE id = $1`

	var plan models.Plan
	err := DB.QueryRow(query, id).Scan(
		&plan.ID,
		&plan.Title,
		&plan.Description,
		&plan.Price,
		&plan.DurationDays,
		&plan.MaxUses,
		&plan.PlanType,
		&plan.CreatedAt,
		&plan.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil // Plan not found
		}
		return nil, err
	}

	return &plan, nil
}

// GetAllPlans retrieves all plans
func GetAllPlans() ([]*models.Plan, error) {
	query := `
		SELECT id, title, description, price, duration_days, max_uses, plan_type, created_at, updated_at
		FROM plans
		ORDER BY price ASC`

	rows, err := DB.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var plans []*models.Plan
	for rows.Next() {
		var plan models.Plan
		if err := rows.Scan(
			&plan.ID,
			&plan.Title,
			&plan.Description,
			&plan.Price,
			&plan.DurationDays,
			&plan.MaxUses,
			&plan.PlanType,
			&plan.CreatedAt,
			&plan.UpdatedAt,
		); err != nil {
			return nil, err
		}
		plans = append(plans, &plan)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return plans, nil
}

// CreateUserSubscription creates a new subscription for a user
func CreateUserSubscription(userID int64, planID int64) (*models.UserSubscription, error) {
	// First get the plan details
	plan, err := GetPlanByID(planID)
	if err != nil {
		return nil, err
	}
	if plan == nil {
		return nil, sql.ErrNoRows
	}

	tx, err := DB.Begin()
	if err != nil {
		return nil, err
	}
	defer func() {
		if err != nil {
			tx.Rollback()
		}
	}()

	// Calculate expiry date if applicable
	var expiryDate *time.Time
	if plan.DurationDays != nil {
		expiry := time.Now().AddDate(0, 0, *plan.DurationDays)
		expiryDate = &expiry
	}

	// Set remaining uses if applicable
	var remainingUses *int
	if plan.MaxUses != nil {
		remaining := *plan.MaxUses
		remainingUses = &remaining
	}

	// Insert subscription
	query := `
		INSERT INTO user_subscriptions (
			user_id, plan_id, purchase_date, expiry_date, 
			status, uses_count, remaining_uses, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id, user_id, plan_id, purchase_date, expiry_date, status, uses_count, remaining_uses, created_at, updated_at`

	now := time.Now()
	var subscription models.UserSubscription
	err = tx.QueryRow(
		query,
		userID,
		planID,
		now,
		expiryDate,
		models.SubscriptionStatusActive,
		0,
		remainingUses,
		now,
		now,
	).Scan(
		&subscription.ID,
		&subscription.UserID,
		&subscription.PlanID,
		&subscription.PurchaseDate,
		&subscription.ExpiryDate,
		&subscription.Status,
		&subscription.UsesCount,
		&subscription.RemainingUses,
		&subscription.CreatedAt,
		&subscription.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	// Deduct credit from user's account
	if plan.Price > 0 {
		// Create a credit transaction record
		txnQuery := `
			INSERT INTO credit_transactions (
				user_id, amount, description, transaction_type, related_subscription_id, created_at
			)
			VALUES ($1, $2, $3, $4, $5, $6)`

		_, err = tx.Exec(
			txnQuery,
			userID,
			-plan.Price,
			"Purchase of plan: "+plan.Title,
			"subscription",
			subscription.ID,
			now,
		)

		if err != nil {
			return nil, err
		}

		// Update user credit
		creditUpdateQuery := `
			UPDATE users
			SET credit = credit - $1, updated_at = $2
			WHERE id = $3`

		_, err = tx.Exec(creditUpdateQuery, plan.Price, now, userID)
		if err != nil {
			return nil, err
		}
	}

	// Commit the transaction
	if err = tx.Commit(); err != nil {
		return nil, err
	}

	subscription.Plan = plan
	return &subscription, nil
}

// GetUserSubscriptions retrieves all subscriptions for a user
func GetUserSubscriptions(userID int64) ([]*models.UserSubscription, error) {
	query := `
		SELECT 
			s.id, s.user_id, s.plan_id, s.purchase_date, s.expiry_date, 
			s.status, s.uses_count, s.remaining_uses, s.created_at, s.updated_at,
			p.id, p.title, p.description, p.price, p.duration_days, 
			p.max_uses, p.plan_type, p.created_at, p.updated_at
		FROM user_subscriptions s
		JOIN plans p ON s.plan_id = p.id
		WHERE s.user_id = $1
		ORDER BY s.purchase_date DESC`

	rows, err := DB.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var subscriptions []*models.UserSubscription
	for rows.Next() {
		var sub models.UserSubscription
		var plan models.Plan

		if err := rows.Scan(
			&sub.ID,
			&sub.UserID,
			&sub.PlanID,
			&sub.PurchaseDate,
			&sub.ExpiryDate,
			&sub.Status,
			&sub.UsesCount,
			&sub.RemainingUses,
			&sub.CreatedAt,
			&sub.UpdatedAt,
			&plan.ID,
			&plan.Title,
			&plan.Description,
			&plan.Price,
			&plan.DurationDays,
			&plan.MaxUses,
			&plan.PlanType,
			&plan.CreatedAt,
			&plan.UpdatedAt,
		); err != nil {
			return nil, err
		}

		sub.Plan = &plan

		// Update subscription status if needed
		if sub.CheckAndUpdateStatus() {
			// Status changed, update in DB
			updateQuery := `
				UPDATE user_subscriptions
				SET status = $1, updated_at = $2
				WHERE id = $3`

			_, err := DB.Exec(updateQuery, sub.Status, time.Now(), sub.ID)
			if err != nil {
				return nil, err
			}
		}

		subscriptions = append(subscriptions, &sub)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return subscriptions, nil
}

// GetActiveUserSubscriptions retrieves active subscriptions for a user
func GetActiveUserSubscriptions(userID int64) ([]*models.UserSubscription, error) {
	query := `
		SELECT 
			s.id, s.user_id, s.plan_id, s.purchase_date, s.expiry_date, 
			s.status, s.uses_count, s.remaining_uses, s.created_at, s.updated_at,
			p.id, p.title, p.description, p.price, p.duration_days, 
			p.max_uses, p.plan_type, p.created_at, p.updated_at
		FROM user_subscriptions s
		JOIN plans p ON s.plan_id = p.id
		WHERE s.user_id = $1 AND s.status = $2
		ORDER BY s.purchase_date DESC`

	rows, err := DB.Query(query, userID, models.SubscriptionStatusActive)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var subscriptions []*models.UserSubscription
	for rows.Next() {
		var sub models.UserSubscription
		var plan models.Plan

		if err := rows.Scan(
			&sub.ID,
			&sub.UserID,
			&sub.PlanID,
			&sub.PurchaseDate,
			&sub.ExpiryDate,
			&sub.Status,
			&sub.UsesCount,
			&sub.RemainingUses,
			&sub.CreatedAt,
			&sub.UpdatedAt,
			&plan.ID,
			&plan.Title,
			&plan.Description,
			&plan.Price,
			&plan.DurationDays,
			&plan.MaxUses,
			&plan.PlanType,
			&plan.CreatedAt,
			&plan.UpdatedAt,
		); err != nil {
			return nil, err
		}

		sub.Plan = &plan

		// Check if subscription is actually expired
		if sub.IsExpired() {
			// Update status in DB
			updateQuery := `
				UPDATE user_subscriptions
				SET status = $1, updated_at = $2
				WHERE id = $3`

			_, err := DB.Exec(updateQuery, models.SubscriptionStatusExpired, time.Now(), sub.ID)
			if err != nil {
				return nil, err
			}

			// Skip this subscription as it's expired
			continue
		}

		subscriptions = append(subscriptions, &sub)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return subscriptions, nil
}

// RecordSubscriptionUsage records usage of a subscription
func RecordSubscriptionUsage(subscriptionID int64, count int) error {
	// First get the subscription details
	query := `
		SELECT id, user_id, plan_id, remaining_uses, uses_count, status
		FROM user_subscriptions
		WHERE id = $1`

	var sub models.UserSubscription
	err := DB.QueryRow(query, subscriptionID).Scan(
		&sub.ID,
		&sub.UserID,
		&sub.PlanID,
		&sub.RemainingUses,
		&sub.UsesCount,
		&sub.Status,
	)

	if err != nil {
		return err
	}

	// Check if subscription is active
	if sub.Status != models.SubscriptionStatusActive {
		return sql.ErrNoRows // Subscription not active
	}

	// Check if there are enough uses remaining
	if sub.RemainingUses != nil && *sub.RemainingUses < count {
		return sql.ErrNoRows // Not enough uses remaining
	}

	// Update usage counts
	updateQuery := `
		UPDATE user_subscriptions
		SET uses_count = uses_count + $1,
			remaining_uses = CASE WHEN remaining_uses IS NOT NULL THEN remaining_uses - $1 ELSE NULL END,
			updated_at = $2
		WHERE id = $3`

	_, err = DB.Exec(updateQuery, count, time.Now(), subscriptionID)
	if err != nil {
		return err
	}

	return nil
}

// GetCreditTransactions retrieves credit transactions for a user
func GetCreditTransactions(userID int64, limit, offset int) ([]*models.CreditTransaction, error) {
	query := `
		SELECT id, user_id, amount, description, transaction_type, related_subscription_id, created_at
		FROM credit_transactions
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3`

	rows, err := DB.Query(query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var transactions []*models.CreditTransaction
	for rows.Next() {
		var txn models.CreditTransaction
		if err := rows.Scan(
			&txn.ID,
			&txn.UserID,
			&txn.Amount,
			&txn.Description,
			&txn.TransactionType,
			&txn.RelatedSubscriptionID,
			&txn.CreatedAt,
		); err != nil {
			return nil, err
		}
		transactions = append(transactions, &txn)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return transactions, nil
}
