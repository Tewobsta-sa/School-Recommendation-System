-- Advertisement and one-time payment module (external advertisers, no accounts)

CREATE TABLE `payment` (
    `payment_id` INTEGER NOT NULL AUTO_INCREMENT,
    `amount` DECIMAL(10, 2) NOT NULL,
    `currency` VARCHAR(10) NOT NULL DEFAULT 'ETB',
    `method` ENUM('telebirr', 'cbe', 'bank_transfer') NULL,
    `status` ENUM('pending', 'completed', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    `transaction_id` VARCHAR(100) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `payment_transaction_id_key`(`transaction_id`),
    INDEX `payment_status_idx`(`status`),
    PRIMARY KEY (`payment_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `advertisement` (
    `advertisement_id` INTEGER NOT NULL AUTO_INCREMENT,
    `company_name` VARCHAR(150) NOT NULL,
    `contact_phone` VARCHAR(15) NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `description` TEXT NULL,
    `image_url` VARCHAR(255) NULL,
    `target_url` VARCHAR(255) NOT NULL,
    `placement_type` ENUM('banner', 'sidebar', 'featured') NOT NULL DEFAULT 'banner',
    `duration_days` INTEGER NOT NULL,
    `start_date` DATETIME(3) NULL,
    `end_date` DATETIME(3) NULL,
    `status` ENUM(
        'pending_payment',
        'payment_pending_verification',
        'active',
        'rejected',
        'expired'
    ) NOT NULL DEFAULT 'pending_payment',
    `impressions` INTEGER NOT NULL DEFAULT 0,
    `clicks` INTEGER NOT NULL DEFAULT 0,
    `payment_id` INTEGER NULL,
    `approved_by` INTEGER NULL,
    `approved_at` DATETIME(3) NULL,
    `reject_reason` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `advertisement_payment_id_key`(`payment_id`),
    INDEX `advertisement_status_idx`(`status`),
    INDEX `advertisement_placement_type_idx`(`placement_type`),
    INDEX `advertisement_start_date_end_date_idx`(`start_date`, `end_date`),
    PRIMARY KEY (`advertisement_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `advertisement` ADD CONSTRAINT `advertisement_payment_id_fkey` FOREIGN KEY (`payment_id`) REFERENCES `payment`(`payment_id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `advertisement` ADD CONSTRAINT `advertisement_approved_by_fkey` FOREIGN KEY (`approved_by`) REFERENCES `user`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
