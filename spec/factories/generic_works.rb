# frozen_string_literal: true

FactoryBot.define do
  factory :generic_work, aliases: [:work] do
    title { ["Test title"] }
    visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    state { "complete" }

    transient do
      user { FactoryBot.create(:user) }
    end

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    factory :generic_work_with_one_file, aliases: [:work_with_one_file] do
      after(:build) do |work, evaluator|
        work.ordered_members << file_set = FactoryBot.create(
          :file_set,
          :image,
          user: evaluator.user,
          title: ['A Contained FileSet'],
          label: 'world.png'
        )
        work.representative = file_set if work.representative_id.blank?
        work.thumbnail = file_set if work.thumbnail_id.blank?
        work.save
      end
    end

    factory :generic_work_with_one_attachment do
      after(:build) do |work|
        work.ordered_members << attachment = FactoryBot.create(
          :attachment_with_one_file
        )
        work.representative = attachment if work.representative_id.blank?
        work.thumbnail = attachment if work.thumbnail_id.blank?
        work.save
      end
    end

    factory :generic_work_with_one_restricted_attachment do
      title { ["Test GenericWork title"] }
      after(:build) do |work|
        work.ordered_members << attachment = FactoryBot.create(
          :attachment_with_one_file,
          title: ['Attachment title'],
          visibility: 'restricted',
          bulkrax_identifier: "1234-5678"
        )
        work.representative = attachment if work.representative_id.blank?
        work.thumbnail = attachment if work.thumbnail_id.blank?
        work.save
      end
    end

    factory :generic_work_with_two_attachments do
      after(:build) do |work|
        work.ordered_members << attachment = FactoryBot.create(
          :attachment_with_one_file
        )
        work.ordered_members << FactoryBot.create(
          :attachment_with_one_file
        )
        work.representative = attachment if work.representative_id.blank?
        work.thumbnail = attachment if work.thumbnail_id.blank?
        work.save
      end
    end

    factory :generic_work_with_one_attachment_and_one_image do
      after(:build) do |work|
        work.ordered_members << attachment = FactoryBot.create(
          :attachment_with_one_file
        )
        work.ordered_members << FactoryBot.create(
          :image
        )
        work.representative = attachment if work.representative_id.blank?
        work.thumbnail = attachment if work.thumbnail_id.blank?
        work.save
      end
    end
  end
end
