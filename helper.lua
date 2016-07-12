lfs = require("lfs")

tryCatch = function(func)
  local result, err = pcall(func);
  print("result:"..(result and "true" or "false").." \nerr:"..(err or "null"));
end

function forEachAllPids(handle, self)
  local path = "/proc"
  for file in lfs.dir(path) do
    if (file ~= "." and file ~= ".." and string.match(file, "%d+") ~= nil) then
      local fullPath = path.."/"..file;
      local attr = lfs.attributes(fullPath)
      if (attr.mode == "directory") then
        local ok = handle(file, fullPath, self);
        if ok ~= true then
          break;
        end
      end
    end
  end
end

--return a table
function getPidsWith(targetUid)
  local function handle(pid, path, data)
    local uid = getUidWithPid(pid);
    if uid == targetUid then
      data[pid] = uid;
    end
    return true
  end

  local pids = {}
  forEachAllPids(handle, pids);

  return pids;
end

function readTcpAvailablePorts(pid, tcp)
  local path = "/proc/"..pid.."/net/"..tcp;
  local file = io.open(path, "r");
  local ports = {};
  local line = file:read("*line")
  while line do
    for port, state in string.gmatch(line, "%d+: %w+:(%w%w%w%w) %w+:%w%w%w%w (%w%w)") do
       if state ~= "07" then
         ports[port] = port;
       end
    end
    line = file:read("*line")
  end
  file:close();
  return ports;
end

function add(x,y)
   return x + y
end

function isDigit(str)
   return string.match(str, "%d+") ~= nil;
end

function readFile()
  local file = io.open("helper.lua", "r");
  local data = file:read("*a");
  print(data);
  file:close();
end

function readCmdline(pid)
  local path = "/proc/"..pid.."/cmdline";
  local file = io.open(path, "r");
  local data = file:read("*line");
  file:close();
  return data;
end

function readCmdlineAndCompare(pid, targetCmdLine)
  local cmdline = readCmdline(pid);

  if (cmdline == nil) then
    return false;
  end

  return string.match(cmdline, targetCmdLine) ~= nil;
end

function getUidWithPid(pid)
  local path = "/proc/"..pid.."/status";
  local file = io.open(path, "r");
  local result = nil;
  local lfs = require("lfs")
  while true do
    local line = file:read()
    if line == nil then break end
    result = string.match(line, "Uid:%s+(%d+)");
    if (result ~= nil) then break end
  end
  file:close();
  return result;
end

function getUidWithCmdline (targetCmdLine)
  local tmpUid = nil;
  local function handle(pid, path)
    local cmdline = readCmdline(pid);
    if cmdline ~= nil then
      local result = string.find(cmdline, targetCmdLine);
      if result ~= nil then
        tmpUid = getUidWithPid(pid);
        return false
      end
    end
    return true
  end

  forEachAllPids(handle);

  return tmpUid;
end

function listPortWithCmdLine (targetCmdLine)
  local currentUid = getUidWithCmdline(targetCmdLine);
  local pids = getPidsWith(currentUid);
  local allPorts = {};
  local result = {};

  --list all ports
  for pid,uid in pairs(pids) do
    local ports = readTcpAvailablePorts(pid, "tcp");
    for port,v in pairs(ports) do
      allPorts[port] = port;
    end

    local ports = readTcpAvailablePorts(pid, "tcp6");
    for port,v in pairs(ports) do
      allPorts[port] = port;
    end
  end

  for k,v in pairs(allPorts) do
    local hi = "0x"..string.sub(k, 0, 2)
    local lo = "0x"..string.sub(k, 3)
    hi = tonumber(string.format("%d",hi))
    lo = tonumber(string.format("%d",lo))
    local port = hi * 0x100 + lo
    print(string.format("available port: %d", port))
    result[port] = port
  end

  return result;
end

function checkAndRecordPort (targetPort, cmdline)
  if targetPort == 80 or targetPort == 443 or targetPort == 21 then
    return -1;
  end

  local myPorts = listPortWithCmdLine(cmdline);
  local result = 0;

  if myPorts[targetPort] ~= nil then
    result = 1;
  end

  return result;
end
