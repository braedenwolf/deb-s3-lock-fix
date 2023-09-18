require "aws-sdk-dynamodb"
require "securerandom"
require "etc"

class Deb::S3::Lock
  attr_reader :user, :host_with_uuid

  DYNAMODB_TABLE_NAME = 'deb-s3-lock'

  def initialize(user, host_with_uuid)
    @user = user
    @host_with_uuid = host_with_uuid
  end

  def self.dynamodb
    @dynamodb ||= begin
      validate_environment_variables!
      Aws::DynamoDB::Client.new(
        access_key_id: ENV['DEB_S3_LOCK_ACCESS_KEY_ID'],
        secret_access_key: ENV['DEB_S3_LOCK_SECRET_ACCESS_KEY'],
        region: ENV['AWS_BUILDERS_REGION']
      )
    end
  end

  def self.validate_environment_variables!
    %w[DEB_S3_LOCK_ACCESS_KEY_ID DEB_S3_LOCK_SECRET_ACCESS_KEY AWS_BUILDERS_REGION].each do |var|
      raise "Environment variable #{var} not set." unless ENV[var]
    end
  end

  class << self
    def lock(codename, max_attempts = 60, max_wait_interval = 10)
      uuid = SecureRandom.uuid
      lock_body = "#{Etc.getlogin}@#{Socket.gethostname}-#{uuid}"
      lock_key = codename

      $stderr.puts("Current job's hostname with UUID: #{lock_body}")

      max_attempts.times do |i|
        wait_interval = [2**i, max_wait_interval].min

        begin
          dynamodb.put_item({
            table_name: DYNAMODB_TABLE_NAME,
            item: {
              'lock_key' => lock_key,
              'lock_body' => lock_body
            },
            condition_expression: "attribute_not_exists(lock_key)"
          })
          return
        rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
          lock_holder = current_lock_holder(codename)
          current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
          $stderr.puts("[#{current_time}] Repository is locked by another user: #{lock_holder.user} at host #{lock_holder.host_with_uuid}")
          $stderr.puts("Attempting to obtain a lock after #{wait_interval} second(s).")
          sleep(wait_interval)
        end
      end

      raise "Unable to obtain a lock after #{max_attempts} attemtps, giving up."
    end

    def unlock(codename)
      dynamodb.delete_item({
        table_name: DYNAMODB_TABLE_NAME,
        key: {
          'lock_key' => codename
        }
      })
    end

    def current_lock_holder(codename)
      response = dynamodb.get_item({
        table_name: DYNAMODB_TABLE_NAME,
        key: {
          'lock_key' => codename
        }
      })

      if response.item
        lockdata = response.item['lock_body']
        user, host_with_uuid = lockdata.split("@", 2)
        Deb::S3::Lock.new(user, host_with_uuid)
      else
        Deb::S3::Lock.new("unknown", "unknown")
      end
    end

    private :dynamodb, :validate_environment_variables!
  end
end
