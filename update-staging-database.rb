def instance_status
 `aws rds describe-db-instances --db-instance-identifier district-steam-staging \
                                --query 'DBInstances[0].[DBInstanceStatus][0]'`
end

def deleted?
  instance_status.match(/^$/)
end

def available?
  instance_status.match('available')
end

def wait_for_status_deleted
  until deleted?
    puts "Current status: #{instance_status.chomp}"
    puts "Awaited status: \"\"..."
    sleep 60
  end
end

def wait_for_status_available
  until available?
    puts "Current status: #{instance_status.chomp}"
    puts "Awaited status: \"available\"..."
    sleep 60
  end
end

def delete_instance
  return if deleted?
  `aws rds delete-db-instance --db-instance-identifier district-steam-staging \
                              --skip-final-snapshot`
end

def restore_instance
  `aws rds restore-db-instance-to-point-in-time --target-db-instance-identifier district-steam-staging \
                                                --source-db-instance-identifier district-steam \
                                                --db-subnet-group district-steam-public \
                                                --port 3306 \
                                                --use-latest-restorable-time \
                                                --publicly-accessible`
end

def add_security_group
  `aws rds modify-db-instance --db-instance-identifier district-steam-staging \
                              --vpc-security-group-ids sg-30bac855 \
                              --apply-immediately`
end

# Delete the current staging db
puts 'Deleting staging-db...'
delete_instance
wait_for_status_deleted
puts 'Deletion complete!'

# Create a fresh staging db with the latest backup from production
puts 'Restoring staging-db...'
restore_instance
wait_for_status_available
puts 'Restoration complete!'

# Add the Database Server security group
puts 'Adding security group...'
add_security_group
puts 'Security group updated!'

puts '========================='
puts 'Database update complete!'
puts '========================='
