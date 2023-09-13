let klarkc = builtins.readFile ./klarkc.pub; in
{
  "env.age".publicKeys = [ klarkc ];
}
