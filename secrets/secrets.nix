let ssdinarch = builtins.readFile ./ssdinarch.pub; in
{
  "env.age".publicKeys = [ ssdinarch ];
}
