module Fetch.Wrapper where
--module Fetch.Wrapper (class IsRequest, Fetch, Request, Response) where
--
--import Effect.Aff (Aff)
--import Fetch (Response, HighlevelRequestOptions) as F
--import Prim.RowList (class RowToList)
--import Prim.Row (class Union)
--import Type.Row.Homogeneous (class HomogeneousRowList)
--
--type Response
--  = F.Response
--
--class IsRequest r
--  
--newtype Request input = Request input
--
--type Fetch r
--  = IsRequest r =>
--    String ->
--    input ->
--    Aff Response