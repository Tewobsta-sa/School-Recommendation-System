/*
  Warnings:

  - You are about to drop the column `approved_at` on the `advertisement` table. All the data in the column will be lost.
  - You are about to drop the column `approved_by` on the `advertisement` table. All the data in the column will be lost.
  - The values [sidebar,featured] on the enum `advertisement_placement_type` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `method` on the `payment` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[chappa_checkout_id]` on the table `payment` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `contact_email` to the `advertisement` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE `advertisement` DROP FOREIGN KEY `advertisement_approved_by_fkey`;

-- DropIndex
DROP INDEX `advertisement_approved_by_fkey` ON `advertisement`;

-- AlterTable
ALTER TABLE `achievement` MODIFY `documents` LONGTEXT NULL;

-- AlterTable
ALTER TABLE `advertisement` DROP COLUMN `approved_at`,
    DROP COLUMN `approved_by`,
    ADD COLUMN `chappa_payment_url` VARCHAR(255) NULL,
    ADD COLUMN `chappa_transaction_id` VARCHAR(100) NULL,
    ADD COLUMN `contact_email` VARCHAR(100) NOT NULL,
    MODIFY `placement_type` ENUM('banner', 'popup') NOT NULL DEFAULT 'banner',
    MODIFY `status` ENUM('pending_review', 'awaiting_payment', 'pending_payment', 'payment_pending_verification', 'active', 'rejected', 'expired') NOT NULL DEFAULT 'pending_review';

-- AlterTable
ALTER TABLE `payment` DROP COLUMN `method`,
    ADD COLUMN `chappa_checkout_id` VARCHAR(100) NULL,
    ADD COLUMN `chappa_reference` VARCHAR(100) NULL;

-- AlterTable
ALTER TABLE `preference` MODIFY `min_budget` DECIMAL(10, 2) NULL,
    MODIFY `max_budget` DECIMAL(10, 2) NULL,
    MODIFY `curriculum` ENUM('local', 'international') NULL,
    MODIFY `distance` INTEGER NULL;

-- AlterTable
ALTER TABLE `recommendation_history` MODIFY `features` LONGTEXT NULL;

-- AlterTable
ALTER TABLE `recommended_school` MODIFY `features` LONGTEXT NULL;

-- AlterTable
ALTER TABLE `verification_request` MODIFY `documents` LONGTEXT NULL;

-- CreateIndex
CREATE UNIQUE INDEX `payment_chappa_checkout_id_key` ON `payment`(`chappa_checkout_id`);
