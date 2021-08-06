require 'spec_helper'
require 'support/components/notifications/center'

describe "Notification center", type: :feature, js: true do
  let!(:project) { FactoryBot.create :project }
  let!(:recipient) do
    # Needs to take place before the work package is created so that the notification listener is set up
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages]
  end
  let!(:work_package) do
    FactoryBot.create :work_package, project: project
  end
  let(:notification) do
    # Will have been created via the JOURNAL_CREATED event listeners
    work_package.journals.last.notifications.first
  end

  let(:center) { ::Components::Notifications::Center.new }

  describe 'notification for a new journal' do
    current_user { recipient }

    it 'will not show all details of the journal' do
      visit home_path
      center.expect_bell_count 1
      center.open

      center.expect_work_package_item notification
      center.click_item notification
      center.expect_expanded notification

      center.within_item(notification) do
        expect(page).to have_text "The work package was created."
      end
    end
  end

  describe 'basic use case' do
    current_user { recipient }

    it 'can see the notification and dismiss it' do
      visit home_path
      center.expect_bell_count 1
      center.open

      center.expect_work_package_item notification
      center.mark_all_read
      center.expect_closed

      center.expect_bell_count 0
      notification.reload
      expect(notification.read_ian).to be_truthy
    end

    it 'can expand the notification to mark it as read' do
      visit home_path
      center.expect_bell_count 1
      center.open

      center.click_item notification
      center.expect_expanded notification
      center.expect_read_item notification

      retry_block do
        notification.reload
        raise "Expected notification to be marked read" unless notification.read_ian
      end

      center.close
      center.expect_bell_count 0

      center.open
      center.expect_empty
    end
  end
end
