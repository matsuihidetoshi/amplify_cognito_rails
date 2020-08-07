class Note < ApplicationRecord
  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 255 }

  scope :search, -> (search_params) do
    return if search_params.blank?

    title_like(search_params[:title_like])
      .created_from(search_params[:created_from])
      .created_to(search_params[:created_to])
      .content_like(search_params[:content_like])
  end
  scope :title_like, -> (title_like) { where('title LIKE ?', "%#{title_like}%") if title_like.present? }
  scope :created_from, -> (created_from) { where('? <= created_at', created_from) if created_from.present? }
  scope :created_to, -> (created_to) { where('created_at <= ?', created_to) if created_to.present? }
  scope :content_like, -> (content_like) { where('content LIKE ?', "%#{content_like}%") if content_like.present? }
end
