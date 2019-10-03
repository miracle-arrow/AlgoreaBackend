-- +migrate Up
ALTER TABLE `users_items` DROP COLUMN `contest_started_at`;

DROP TRIGGER `after_insert_users_items`;
-- +migrate StatementBegin
CREATE TRIGGER `after_insert_users_items` AFTER INSERT ON `users_items` FOR EACH ROW BEGIN INSERT INTO `history_users_items` (`id`,`version`,`user_id`,`item_id`,`active_attempt_id`,`score`,`score_computed`,`score_reeval`,`score_diff_manual`,`score_diff_comment`,`submissions_attempts`,`tasks_tried`,`children_validated`,`validated`,`finished`,`key_obtained`,`tasks_with_help`,`hints_requested`,`hints_cached`,`corrections_read`,`precision`,`autonomy`,`started_at`,`validated_at`,`best_answer_at`,`latest_answer_at`,`thread_started_at`,`latest_hint_at`,`finished_at`,`latest_activity_at`,`ranked`,`all_lang_prog`,`state`,`answer`) VALUES (NEW.`id`,@curVersion,NEW.`user_id`,NEW.`item_id`,NEW.`active_attempt_id`,NEW.`score`,NEW.`score_computed`,NEW.`score_reeval`,NEW.`score_diff_manual`,NEW.`score_diff_comment`,NEW.`submissions_attempts`,NEW.`tasks_tried`,NEW.`children_validated`,NEW.`validated`,NEW.`finished`,NEW.`key_obtained`,NEW.`tasks_with_help`,NEW.`hints_requested`,NEW.`hints_cached`,NEW.`corrections_read`,NEW.`precision`,NEW.`autonomy`,NEW.`started_at`,NEW.`validated_at`,NEW.`best_answer_at`,NEW.`latest_answer_at`,NEW.`thread_started_at`,NEW.`latest_hint_at`,NEW.`finished_at`,NEW.`latest_activity_at`,NEW.`ranked`,NEW.`all_lang_prog`,NEW.`state`,NEW.`answer`); END
-- +migrate StatementEnd
DROP TRIGGER `before_update_users_items`;
-- +migrate StatementBegin
CREATE TRIGGER `before_update_users_items` BEFORE UPDATE ON `users_items` FOR EACH ROW BEGIN IF NEW.version <> OLD.version THEN SET @curVersion = NEW.version; ELSE SELECT ROUND(UNIX_TIMESTAMP(CURTIME(2)) * 10) INTO @curVersion; END IF; IF NOT (OLD.`id` = NEW.`id` AND OLD.`user_id` <=> NEW.`user_id` AND OLD.`item_id` <=> NEW.`item_id` AND OLD.`active_attempt_id` <=> NEW.`active_attempt_id` AND OLD.`score` <=> NEW.`score` AND OLD.`score_computed` <=> NEW.`score_computed` AND OLD.`score_reeval` <=> NEW.`score_reeval` AND OLD.`score_diff_manual` <=> NEW.`score_diff_manual` AND OLD.`score_diff_comment` <=> NEW.`score_diff_comment` AND OLD.`tasks_tried` <=> NEW.`tasks_tried` AND OLD.`children_validated` <=> NEW.`children_validated` AND OLD.`validated` <=> NEW.`validated` AND OLD.`finished` <=> NEW.`finished` AND OLD.`key_obtained` <=> NEW.`key_obtained` AND OLD.`tasks_with_help` <=> NEW.`tasks_with_help` AND OLD.`hints_requested` <=> NEW.`hints_requested` AND OLD.`hints_cached` <=> NEW.`hints_cached` AND OLD.`corrections_read` <=> NEW.`corrections_read` AND OLD.`precision` <=> NEW.`precision` AND OLD.`autonomy` <=> NEW.`autonomy` AND OLD.`started_at` <=> NEW.`started_at` AND OLD.`validated_at` <=> NEW.`validated_at` AND OLD.`best_answer_at` <=> NEW.`best_answer_at` AND OLD.`latest_answer_at` <=> NEW.`latest_answer_at` AND OLD.`thread_started_at` <=> NEW.`thread_started_at` AND OLD.`latest_hint_at` <=> NEW.`latest_hint_at` AND OLD.`finished_at` <=> NEW.`finished_at` AND OLD.`ranked` <=> NEW.`ranked` AND OLD.`all_lang_prog` <=> NEW.`all_lang_prog` AND OLD.`state` <=> NEW.`state` AND OLD.`answer` <=> NEW.`answer`) THEN   SET NEW.version = @curVersion;   UPDATE `history_users_items` SET `next_version` = @curVersion WHERE `id` = OLD.`id` AND `next_version` IS NULL;   INSERT INTO `history_users_items` (`id`,`version`,`user_id`,`item_id`,`active_attempt_id`,`score`,`score_computed`,`score_reeval`,`score_diff_manual`,`score_diff_comment`,`submissions_attempts`,`tasks_tried`,`children_validated`,`validated`,`finished`,`key_obtained`,`tasks_with_help`,`hints_requested`,`hints_cached`,`corrections_read`,`precision`,`autonomy`,`started_at`,`validated_at`,`best_answer_at`,`latest_answer_at`,`thread_started_at`,`latest_hint_at`,`finished_at`,`latest_activity_at`,`ranked`,`all_lang_prog`,`state`,`answer`)       VALUES (NEW.`id`,@curVersion,NEW.`user_id`,NEW.`item_id`,NEW.`active_attempt_id`,NEW.`score`,NEW.`score_computed`,NEW.`score_reeval`,NEW.`score_diff_manual`,NEW.`score_diff_comment`,NEW.`submissions_attempts`,NEW.`tasks_tried`,NEW.`children_validated`,NEW.`validated`,NEW.`finished`,NEW.`key_obtained`,NEW.`tasks_with_help`,NEW.`hints_requested`,NEW.`hints_cached`,NEW.`corrections_read`,NEW.`precision`,NEW.`autonomy`,NEW.`started_at`,NEW.`validated_at`,NEW.`best_answer_at`,NEW.`latest_answer_at`,NEW.`thread_started_at`,NEW.`latest_hint_at`,NEW.`finished_at`,NEW.`latest_activity_at`,NEW.`ranked`,NEW.`all_lang_prog`,NEW.`state`,NEW.`answer`) ; END IF; END
-- +migrate StatementEnd
DROP TRIGGER `before_delete_users_items`;
-- +migrate StatementBegin
CREATE TRIGGER `before_delete_users_items` BEFORE DELETE ON `users_items` FOR EACH ROW BEGIN SELECT ROUND(UNIX_TIMESTAMP(CURTIME(2)) * 10) INTO @curVersion; UPDATE `history_users_items` SET `next_version` = @curVersion WHERE `id` = OLD.`id` AND `next_version` IS NULL; INSERT INTO `history_users_items` (`id`,`version`,`user_id`,`item_id`,`active_attempt_id`,`score`,`score_computed`,`score_reeval`,`score_diff_manual`,`score_diff_comment`,`submissions_attempts`,`tasks_tried`,`children_validated`,`validated`,`finished`,`key_obtained`,`tasks_with_help`,`hints_requested`,`hints_cached`,`corrections_read`,`precision`,`autonomy`,`started_at`,`validated_at`,`best_answer_at`,`latest_answer_at`,`thread_started_at`,`latest_hint_at`,`finished_at`,`latest_activity_at`,`ranked`,`all_lang_prog`,`state`,`answer`, `deleted`) VALUES (OLD.`id`,@curVersion,OLD.`user_id`,OLD.`item_id`,OLD.`active_attempt_id`,OLD.`score`,OLD.`score_computed`,OLD.`score_reeval`,OLD.`score_diff_manual`,OLD.`score_diff_comment`,OLD.`submissions_attempts`,OLD.`tasks_tried`,OLD.`children_validated`,OLD.`validated`,OLD.`finished`,OLD.`key_obtained`,OLD.`tasks_with_help`,OLD.`hints_requested`,OLD.`hints_cached`,OLD.`corrections_read`,OLD.`precision`,OLD.`autonomy`,OLD.`started_at`,OLD.`validated_at`,OLD.`best_answer_at`,OLD.`latest_answer_at`,OLD.`thread_started_at`,OLD.`latest_hint_at`,OLD.`finished_at`,OLD.`latest_activity_at`,OLD.`ranked`,OLD.`all_lang_prog`,OLD.`state`,OLD.`answer`, 1); END
-- +migrate StatementEnd

-- +migrate Down
ALTER TABLE `users_items`
    ADD COLUMN `contest_started_at` datetime DEFAULT NULL COMMENT 'Deprecated' AFTER `latest_hint_at`;

DROP TRIGGER `after_insert_users_items`;
-- +migrate StatementBegin
CREATE TRIGGER `after_insert_users_items` AFTER INSERT ON `users_items` FOR EACH ROW BEGIN INSERT INTO `history_users_items` (`id`,`version`,`user_id`,`item_id`,`active_attempt_id`,`score`,`score_computed`,`score_reeval`,`score_diff_manual`,`score_diff_comment`,`submissions_attempts`,`tasks_tried`,`children_validated`,`validated`,`finished`,`key_obtained`,`tasks_with_help`,`hints_requested`,`hints_cached`,`corrections_read`,`precision`,`autonomy`,`started_at`,`validated_at`,`best_answer_at`,`latest_answer_at`,`thread_started_at`,`latest_hint_at`,`finished_at`,`latest_activity_at`,`contest_started_at`,`ranked`,`all_lang_prog`,`state`,`answer`) VALUES (NEW.`id`,@curVersion,NEW.`user_id`,NEW.`item_id`,NEW.`active_attempt_id`,NEW.`score`,NEW.`score_computed`,NEW.`score_reeval`,NEW.`score_diff_manual`,NEW.`score_diff_comment`,NEW.`submissions_attempts`,NEW.`tasks_tried`,NEW.`children_validated`,NEW.`validated`,NEW.`finished`,NEW.`key_obtained`,NEW.`tasks_with_help`,NEW.`hints_requested`,NEW.`hints_cached`,NEW.`corrections_read`,NEW.`precision`,NEW.`autonomy`,NEW.`started_at`,NEW.`validated_at`,NEW.`best_answer_at`,NEW.`latest_answer_at`,NEW.`thread_started_at`,NEW.`latest_hint_at`,NEW.`finished_at`,NEW.`latest_activity_at`,NEW.`contest_started_at`,NEW.`ranked`,NEW.`all_lang_prog`,NEW.`state`,NEW.`answer`); END
-- +migrate StatementEnd
DROP TRIGGER `before_update_users_items`;
-- +migrate StatementBegin
CREATE TRIGGER `before_update_users_items` BEFORE UPDATE ON `users_items` FOR EACH ROW BEGIN IF NEW.version <> OLD.version THEN SET @curVersion = NEW.version; ELSE SELECT ROUND(UNIX_TIMESTAMP(CURTIME(2)) * 10) INTO @curVersion; END IF; IF NOT (OLD.`id` = NEW.`id` AND OLD.`user_id` <=> NEW.`user_id` AND OLD.`item_id` <=> NEW.`item_id` AND OLD.`active_attempt_id` <=> NEW.`active_attempt_id` AND OLD.`score` <=> NEW.`score` AND OLD.`score_computed` <=> NEW.`score_computed` AND OLD.`score_reeval` <=> NEW.`score_reeval` AND OLD.`score_diff_manual` <=> NEW.`score_diff_manual` AND OLD.`score_diff_comment` <=> NEW.`score_diff_comment` AND OLD.`tasks_tried` <=> NEW.`tasks_tried` AND OLD.`children_validated` <=> NEW.`children_validated` AND OLD.`validated` <=> NEW.`validated` AND OLD.`finished` <=> NEW.`finished` AND OLD.`key_obtained` <=> NEW.`key_obtained` AND OLD.`tasks_with_help` <=> NEW.`tasks_with_help` AND OLD.`hints_requested` <=> NEW.`hints_requested` AND OLD.`hints_cached` <=> NEW.`hints_cached` AND OLD.`corrections_read` <=> NEW.`corrections_read` AND OLD.`precision` <=> NEW.`precision` AND OLD.`autonomy` <=> NEW.`autonomy` AND OLD.`started_at` <=> NEW.`started_at` AND OLD.`validated_at` <=> NEW.`validated_at` AND OLD.`best_answer_at` <=> NEW.`best_answer_at` AND OLD.`latest_answer_at` <=> NEW.`latest_answer_at` AND OLD.`thread_started_at` <=> NEW.`thread_started_at` AND OLD.`latest_hint_at` <=> NEW.`latest_hint_at` AND OLD.`finished_at` <=> NEW.`finished_at` AND OLD.`contest_started_at` <=> NEW.`contest_started_at` AND OLD.`ranked` <=> NEW.`ranked` AND OLD.`all_lang_prog` <=> NEW.`all_lang_prog` AND OLD.`state` <=> NEW.`state` AND OLD.`answer` <=> NEW.`answer`) THEN   SET NEW.version = @curVersion;   UPDATE `history_users_items` SET `next_version` = @curVersion WHERE `id` = OLD.`id` AND `next_version` IS NULL;   INSERT INTO `history_users_items` (`id`,`version`,`user_id`,`item_id`,`active_attempt_id`,`score`,`score_computed`,`score_reeval`,`score_diff_manual`,`score_diff_comment`,`submissions_attempts`,`tasks_tried`,`children_validated`,`validated`,`finished`,`key_obtained`,`tasks_with_help`,`hints_requested`,`hints_cached`,`corrections_read`,`precision`,`autonomy`,`started_at`,`validated_at`,`best_answer_at`,`latest_answer_at`,`thread_started_at`,`latest_hint_at`,`finished_at`,`latest_activity_at`,`contest_started_at`,`ranked`,`all_lang_prog`,`state`,`answer`)       VALUES (NEW.`id`,@curVersion,NEW.`user_id`,NEW.`item_id`,NEW.`active_attempt_id`,NEW.`score`,NEW.`score_computed`,NEW.`score_reeval`,NEW.`score_diff_manual`,NEW.`score_diff_comment`,NEW.`submissions_attempts`,NEW.`tasks_tried`,NEW.`children_validated`,NEW.`validated`,NEW.`finished`,NEW.`key_obtained`,NEW.`tasks_with_help`,NEW.`hints_requested`,NEW.`hints_cached`,NEW.`corrections_read`,NEW.`precision`,NEW.`autonomy`,NEW.`started_at`,NEW.`validated_at`,NEW.`best_answer_at`,NEW.`latest_answer_at`,NEW.`thread_started_at`,NEW.`latest_hint_at`,NEW.`finished_at`,NEW.`latest_activity_at`,NEW.`contest_started_at`,NEW.`ranked`,NEW.`all_lang_prog`,NEW.`state`,NEW.`answer`) ; END IF; END
-- +migrate StatementEnd
DROP TRIGGER `before_delete_users_items`;
-- +migrate StatementBegin
CREATE TRIGGER `before_delete_users_items` BEFORE DELETE ON `users_items` FOR EACH ROW BEGIN SELECT ROUND(UNIX_TIMESTAMP(CURTIME(2)) * 10) INTO @curVersion; UPDATE `history_users_items` SET `next_version` = @curVersion WHERE `id` = OLD.`id` AND `next_version` IS NULL; INSERT INTO `history_users_items` (`id`,`version`,`user_id`,`item_id`,`active_attempt_id`,`score`,`score_computed`,`score_reeval`,`score_diff_manual`,`score_diff_comment`,`submissions_attempts`,`tasks_tried`,`children_validated`,`validated`,`finished`,`key_obtained`,`tasks_with_help`,`hints_requested`,`hints_cached`,`corrections_read`,`precision`,`autonomy`,`started_at`,`validated_at`,`best_answer_at`,`latest_answer_at`,`thread_started_at`,`latest_hint_at`,`finished_at`,`latest_activity_at`,`contest_started_at`,`ranked`,`all_lang_prog`,`state`,`answer`, `deleted`) VALUES (OLD.`id`,@curVersion,OLD.`user_id`,OLD.`item_id`,OLD.`active_attempt_id`,OLD.`score`,OLD.`score_computed`,OLD.`score_reeval`,OLD.`score_diff_manual`,OLD.`score_diff_comment`,OLD.`submissions_attempts`,OLD.`tasks_tried`,OLD.`children_validated`,OLD.`validated`,OLD.`finished`,OLD.`key_obtained`,OLD.`tasks_with_help`,OLD.`hints_requested`,OLD.`hints_cached`,OLD.`corrections_read`,OLD.`precision`,OLD.`autonomy`,OLD.`started_at`,OLD.`validated_at`,OLD.`best_answer_at`,OLD.`latest_answer_at`,OLD.`thread_started_at`,OLD.`latest_hint_at`,OLD.`finished_at`,OLD.`latest_activity_at`,OLD.`contest_started_at`,OLD.`ranked`,OLD.`all_lang_prog`,OLD.`state`,OLD.`answer`, 1); END
-- +migrate StatementEnd

INSERT INTO `users_items` (`user_id`, `item_id`, `contest_started_at`)
    SELECT users.id, contest_participations.item_id, contest_participations.entered_at
    FROM contest_participations
         JOIN users ON users.self_group_id = contest_participations.group_id
    WHERE contest_participations.entered_at IS NOT NULL
ON DUPLICATE KEY UPDATE contest_started_at = contest_participations.entered_at;
