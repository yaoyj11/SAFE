defenv Selfie() :-
  spec('Load the principal keypair'),
  principal($1).

defenv GeniRoot() :- 'hBZy2DLtG7qF7CxdZNWusPKdDz6LbA3lBDFIBDGbHTo'.

defenv MyAnchorSet() :- anchorSet().

//
// Identity set (apply to all participants)
//

defcon makeMyIdentitySet(?CN) :-
  spec("Construct the identity set for self"),
  {
    principal($SelfKey) :- spec("identity set for $CN").
  }.

defcon makeMySubjectSet() :-
  spec("Construct the subject set for self"),
  {
    link($Self).
    label("subject($Self)").
  }.

defcon makeCapabilitySet(?Token, ?Scid) :-
  spec("Construct a capability set for ?Scid"),
  {
    link($Token).
    label("capability($Scid)").
  }.

defcon addTokenToSubjectSet(?Token) :-
  spec("Add a token to the user's subject set. Invoke after the user gets a delegation"),
  {
    link($Token).
    label("subject($Self)").
  }.

defpost postIdSet(?CN) :- [makeMyIdentitySet(?CN)].

defpost postSubjectSet() :- [makeMySubjectSet()].

defpost passDelegation(?Token, ?Scid) :-
  ?CapSetRef := label($Self, "capability(?Scid)"),
  [makeCapabilitySet(?Token, ?Scid), addTokenToSubjectSet(?CapSetRef)].


//
// Federation policy: trust structure and user/PI registration
//

defcon trustStructure() :-
  spec('Federation trust structure: adopted by all participants'),
  {
    memberAuthority(?MA) :- geniRoot(?Geni), ?Geni: memberAuthority(?MA).
    sliceAuthority(?SA) :- geniRoot(?Geni), ?Geni: sliceAuthority(?SA).
    projectAuthority(?PA) :- geniRoot(?Geni), ?Geni: projectAuthority(?PA).
    geniProxy(?GeniProxy) :- geniRoot(?Geni), ?Geni: geniProxy(?GeniProxy).
    aggregate(?Agg) :- geniRoot(?Geni), ?Geni: aggregate(?Agg).
    gmoc(?GeniMOC) :- geniRoot(?Geni), ?Geni: gmoc(?GeniMOC).
    label('geni/trust-structure').
  }.

defcon registeredUserPolicy() :-
  spec('Federation policy for registered users and PIs: adopted by all participants'),
  {
    geniUser(?User) :- memberAuthority(?MA), ?MA: geniUser(?User).
    geniPI(?User) :- memberAuthority(?MA), ?MA: geniPI(?User).
    label('geni/registered-user').
  }.

definit trustStructure(), registeredUserPolicy().

//
// Federation root: endorsements
//

defcon endorseMA(?MA) :-
  spec('endorse a member authority'),
  {
    memberAuthority($MA) :- spec("geni endorses a member authority $MA").
    label("ma/$MA").
  }.

defcon endorsePA(?PA) :-
  spec('endorse a project authority'),
  {
    projectAuthority($PA) :- spec("geni endorses a project authority $PA").
    label("pa/$PA").
  }.

defcon endorseSA(?SA) :-
  spec('endorse a slice authority'),
  {
    sliceAuthority($SA) :- spec("geni endorses a slice authority $SA").
    label("sa/$SA").
  }.

defcon endorseCP(?CP) :-
  spec('endorse an aggregate'),
  {
    aggregate($CP) :- spec("geni endorses an aggregate $CP").
    label("aggregate/$CP").
  }.

defpost postMAEndorsement(?MA) :- [endorseMA(?MA)].
defpost postPAEndorsement(?PA) :- [endorsePA(?PA)].
defpost postSAEndorsement(?SA) :- [endorseSA(?SA)].
defpost postCPEndorsement(?CP) :- [endorseCP(?CP)].


//
// MA: endorsements for registered users and PIs.
//

defcon endorsePI(?PI) :-
  spec('Endorse a geni PI'),
  ?CapSetRef := label($Self, "capability(MA)"),
  {
    geniUser($PI).
    geniPI($PI).
    link($CapSetRef).
    label("pi/$PI").
  }.

defcon endorseUser(?User) :- 
  spec('Endorse a geni user'),
  ?CapSetRef := label($Self, "capability(MA)"),
  {
    geniUser($User).
    link($CapSetRef).
    label("user/$User").
  }.

defpost postPIEndorsement(?PI) :- [endorsePI(?PI)].
defpost postUserEndorsement(?User) :- [endorseUser(?User)].


//
// PA: projects and their policy sets
//

defcon memberSet() :- 
  {
    member(?User, ?Project) :-
      member(?User, ?Project, _).

    member(?User, ?Project, true) :-
      owner(?User, ?Project).
 
    member(?User, ?Project, ?Delegatable) :-
      ?Delegator: delegateMember(?User, ?Project, ?Delegatable),
      member(?Delegator, ?Project, true).
 
    memberPrivilege(?User, ?Project, instantiate, ?Delegatable) :- 
      member(?User, ?Project, ?Delegatable).

    memberPrivilege(?User, ?Project, ?Priv, ?Delegatable) :-
      delegatesMemberPrivilege(?Delegator, ?User, ?Project, ?Priv, ?Delegatable),
      memberPrivilege(?Delegator, ?Project, ?Priv, true).

    delegatesMember(?Delegator, User, ?Project, ?Delegatable) :-
      ?Delegator: delegateMember(?User, ?Project, ?Delegatable).

    delegatesMemberPrivilege(?Delegator, ?User, ?Project, ?Priv, ?Delegatable) :-
      ?Delegator: delegateMemberPrivilege(?User, ?Project, ?Priv, ?Delegatable).
 
    label('pa/standard-project-membership') :- 
      spec('Standard project membership policy').
  }.

defpost postMemberSet() :- 
  [memberSet()].

defcon delegateProjectMembership(?SubjectId, ?ProjectId, ?Delegatable) :-
  ?CapSetRef := label($Self, "capability(?ProjectId)"),
  {
    delegateMember($SubjectId, $ProjectId, $Delegatable).
    link($CapSetRef).
    label("project membership delegation $SubjectId $ProjectId").
  }.

defpost postProjectMembership(?SubjectId, ?ProjectId, ?Delegatable) :- 
  [delegateProjectMembership(?SubjectId, ?ProjectId, ?Delegatable)].


//
// PA authZ policy for project creation.
//
defcon projectPolicySet() :-
  {
    approveProject(?Owner) :-
      geniPI(?Owner).
    label('pa/standard-project-operations').
  }.

definit projectPolicySet().

defcon createProjectSet(?SubjectId, ?ProjectId, ?ProjectMembershipRef) :-
  ?CapSetRef := label($Self, "capability(PA)"),
  {
    owner($SubjectId, $ProjectId).
    project($ProjectId, standard).
    link($ProjectMembershipRef).
    link($CapSetRef).
    label("project/$ProjectId").
  }.

defpost postProjectSet(?SubjectId, ?ProjectId, ?ProjectMembershipRef) :- 
  [createProjectSet(?SubjectId, ?ProjectId, ?ProjectMembershipRef)].

//
// SA: slices and their policy sets
//

defcon standardSliceControlSet() :- 
  {
    controls(?Subject, ?Slice, true) :-
      owner(?Subject, ?Slice).
 
    controls(?Subject, ?Slice, ?Delegatable) :- 
      delegatesControl(?Delegator, ?Subject, ?Slice, ?Delegatable),
      controls(?Delegator, ?Slice, true).
 
    controls(?Subject, ?Slice) :-
      controls(?Subject, ?Slice, _).
 
    controlPrivilege(?Subject, ?Slice, instantiate, ?Delegator) :- 
      controls(?Subject, ?Slice, ?Delegator).
 
    controlPrivilege(?Subject, ?Slice, ?Priv, ?Delegatable) :- 
      delegatesControlPrivilege(?Delegator, ?Subject, ?Slice, ?Priv, ?Delegatable),
      controlPrivilege(?Delegator, ?Slice, ?Priv, true).

    delegatesControl(?Delegator, ?Subject, ?Slice, ?Delegatable) :-
      ?Delegator: delegateControl(?Subject, ?Slice, ?Delegatable).

    delegatesControlPrivilege(?Delegator, ?Subject, ?Slice, ?Priv, ?Delegatable) :-
      ?Delegator: delegatesControlPrivilege(?Subject, ?Slice, ?Priv, ?Delegatable).

    label('sa/standard-slice-control') :- 
      spec('Standard slice control policy').
  }.

defpost postStandardSliceControlSet() :- 
  [standardSliceControlSet()].


defcon standardSliceDefaultPrivilegeSet() :-
  {
    controlPrivilege(?Subject, ?Slice, info, ?Delegatable) :-
      slice(?Slice, ?Project, standard),
      ?PA := rootPrincipal(?Project),
      projectAuthority(?PA),
      ?PA: project(?Project, standard),
      ?PA: memberPrivilege(?Subject, ?Project, info, ?Delegatable).
 
    controlPrivilege(?Subject, ?Slice, stop, true) :- 
      slice(?Slice, ?Project, standard),
      ?PA := rootPrincipal(?Project),
      projectAuthority(?PA),
      ?PA: project(?Project, standard),
      ?PA: owner(?Subject, ?Project).
 
    controlPrivilege(?Subject, ?Slice, info) :- 
      slice(?Slice, ?Project, standard),
      gmoc(?Subject).
 
    controlPrivilege(?Subject, ?Slice, stop) :- 
      slice(?Slice, ?Project, standard),
      gmoc(?Subject).
 
    label('sa/standard-slice-privilege') :- 
      spec('Standard slice default privilege policy').
  }.

defpost postStandardSliceDefaultPrivilegeSet() :- 
  [standardSliceDefaultPrivilegeSet()].

defcon delegateSliceControl(?SubjectId, ?SliceId, ?Delegatable) :-
  ?CapSetRef := label($Self, "capability(?SliceId)"),
  {
    delegateControl($SubjectId, $SliceId, $Delegatable).
    link($CapSetRef).
    label("slice control delegation $SubjectId $SliceId").
  }.

defpost postSliceControl(?SubjectId, ?SliceId, ?Delegatable) :- 
  [delegateSliceControl(?SubjectId, ?SliceId, ?Delegatable)].


//
// SA authZ policy for slice creation.
//
defcon slicePolicySet() :-
  {
    approveSlice(?Subject, ?Project) :-
      ?PA := rootPrincipal(?Project),
      projectAuthority(?PA),
      ?PA: project(?Project, standard),
      ?PA: memberPrivilege(?Subject, ?Project, instantiate, _),
      geniUser(?Subject).

    label('sa/standard-slice-operations').
  }.

definit slicePolicySet().

//
// A newly approved slice is created as a set with links to its policy sets.
//

defcon createSliceSet(?SubjectId, ?SliceId, ?ProjectId, ?SliceControlRef, ?SlicePrivRef) :-
  ?CapSetRef := label($Self, "capability(SA)"),
  {
    owner($SubjectId, $SliceId).
    slice($SliceId, $ProjectId, standard).
    link($SliceControlRef).
    link($SlicePrivRef).
    link($CapSetRef).
    label("slice/$SliceId").
  }.

defpost postSliceSet(?SubjectId, ?SliceId, ?ProjectId, ?SliceControlRef, ?SlicePrivRef) :- 
  [createSliceSet(?SubjectId, ?SliceId, ?ProjectId, ?SliceControlRef, ?SlicePrivRef)].

//
// Aggregate
//

defcon aggregatePolicySet() :- 
  {
     approveSliver(?Subject, ?Slice) :-
       ?SA := rootPrincipal(?Slice),
       ?SA: slice(?Slice, ?Project, standard),
       sliceAuthority(?SA), 
       ?SA: controlPrivilege(?Subject, ?Slice, instantiate, _),
       geniUser(?Subject).
 
     label('aggregate/standard-slice-operations').
  }.

definit aggregatePolicySet().

//
// Omitted: createSliver
// For this demo/benchmark, we're just checking approveSliver authorizations.
// createSliver would show how to represent a sliver and its resources in trust logic.  TBD.
//

//
// Guards
// There are three for primary GENI interfaces:
// pa.createProject, sa.createSlice, agg.createSliver.
// AuthZ for other agg slice operations is similar to approveSliver.
//

defguard createProject() :-
  spec("Guard for ProjectAuthority.createProject"),
  ?PolicyRef := label("pa/standard-project-operations"),
  {
    link($MyAnchorSet).
    link($PolicyRef).
    link($BearerRef).
    approveProject($Subject)?
  }.

defguard createSlice(?ProjectId) :-
  spec("Guard for SliceAuthority.createSlice"),
  ?PolicyRef := label("sa/standard-slice-operations"),
  {
    link($MyAnchorSet).
    link($PolicyRef).
    link($BearerRef). 
    approveSlice($Subject, $ProjectId)?
  }.

defguard createSliver(?SliceId) :-
  spec("Guard for Aggregate.createSliver"),
  ?PolicyRef := label("aggregate/standard-slice-operations"),
  {
    link($MyAnchorSet).
    link($PolicyRef).
    link($BearerRef). 
    approveSliver($Subject, $SliceId)?
  }.

//
// Local example
//

defcon fedEndorsementStub() :-
  ?E1 := endorseMA($Self),
  ?E2 := endorsePA($Self),
  ?E3 := endorseSA($Self),
  ?E4 := endorseCP($Self),
  {
    link($E1).
    link($E2).
    link($E3).
    link($E4).
    label("geni/endorse-self-stub").
  }.

defcon anchorSet() :-
  ?FedStructureRef := label("geni/trust-structure"),
  ?FedUserRef := label("geni/registered-user"),   
  {
    geniRoot($GeniRoot).
    link($FedStructureRef).
    link($FedUserRef).   
    label("geni/anchor-set").
  }.