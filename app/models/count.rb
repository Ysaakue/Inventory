class Count < ApplicationRecord
  belongs_to :client
  has_and_belongs_to_many :employees, join_table: "counts_employees"
  after_save :prepare_count
  after_update :verify_count
  scope :not_completed, -> { where("status != 3") }

  enum status: {
    first_count: 0,
    first_count_completed: 1,
    second_count: 2,
    second_count_completed: 3,
    third_count: 4,
    third_count_completed: 5,
    fourth_count: 6,
    completed: 7
  }

  def prepare_count
    #TODO
  end

  def verify_count
    #TODO
  end

  def as_json option={}
    {
      id: id,
      date: date,
      status: status,
      flags: flags,
      client: client.fantasy_name,
    }
  end

  # Define asynchronous tasks
  handle_asynchronously :prepare_count
  handle_asynchronously :verify_count
end
