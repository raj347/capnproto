-- Copyright (c) 2013, Kenton Varda <temporal@gmail.com>
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice, this
--    list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module Grammar where

import Token (Located)
import Data.Maybe (maybeToList)

data DeclName = AbsoluteName (Located String)
              | RelativeName (Located String)
              | ImportName (Located String)
              | MemberName DeclName (Located String)
              deriving (Show)

declNameImport :: DeclName -> Maybe (Located String)
declNameImport (AbsoluteName _) = Nothing
declNameImport (RelativeName _) = Nothing
declNameImport (ImportName s) = Just s
declNameImport (MemberName parent _) = declNameImport parent

data TypeExpression = TypeExpression DeclName [TypeExpression]
                    deriving (Show)

typeImports :: TypeExpression -> [Located String]
typeImports (TypeExpression name params) =
    maybeToList (declNameImport name) ++ concatMap typeImports params

data Annotation = Annotation DeclName (Located FieldValue) deriving(Show)

annotationImports (Annotation name _) = maybeToList $ declNameImport name

data FieldValue = VoidFieldValue
                | BoolFieldValue Bool
                | IntegerFieldValue Integer
                | FloatFieldValue Double
                | StringFieldValue String
                | IdentifierFieldValue String
                | ListFieldValue [Located FieldValue]
                | RecordFieldValue [(Located String, Located FieldValue)]
                | UnionFieldValue String FieldValue
                deriving (Show)

data ParamDecl = ParamDecl String TypeExpression [Annotation] (Maybe (Located FieldValue))
               deriving (Show)

paramImports (ParamDecl _ t ann _) = typeImports t ++ concatMap annotationImports ann

data AnnotationTarget = FileAnnotation
                      | ConstantAnnotation
                      | EnumAnnotation
                      | EnumValueAnnotation
                      | StructAnnotation
                      | FieldAnnotation
                      | UnionAnnotation
                      | InterfaceAnnotation
                      | MethodAnnotation
                      | ParamAnnotation
                      | AnnotationAnnotation
                      deriving(Eq, Ord, Bounded, Enum)

instance Show AnnotationTarget where
    show FileAnnotation = "file"
    show ConstantAnnotation = "const"
    show EnumAnnotation = "enum"
    show EnumValueAnnotation = "enumerant"
    show StructAnnotation = "struct"
    show FieldAnnotation = "field"
    show UnionAnnotation = "union"
    show InterfaceAnnotation = "interface"
    show MethodAnnotation = "method"
    show ParamAnnotation = "param"
    show AnnotationAnnotation = "annotation"

data Declaration = AliasDecl (Located String) DeclName
                 | ConstantDecl (Located String) TypeExpression [Annotation] (Located FieldValue)
                 | EnumDecl (Located String) [Annotation] [Declaration]
                 | EnumValueDecl (Located String) (Located Integer) [Annotation]
                 | StructDecl (Located String) [Annotation] [Declaration]
                 | FieldDecl (Located String) (Located Integer)
                             TypeExpression [Annotation] (Maybe (Located FieldValue))
                 | UnionDecl (Located String) (Located Integer) [Annotation] [Declaration]
                 | InterfaceDecl (Located String) [Annotation] [Declaration]
                 | MethodDecl (Located String) (Located Integer) [ParamDecl]
                              TypeExpression [Annotation]
                 | AnnotationDecl (Located String) TypeExpression [Annotation] [AnnotationTarget]
                 deriving (Show)

declarationName :: Declaration -> Maybe (Located String)
declarationName (AliasDecl n _)          = Just n
declarationName (ConstantDecl n _ _ _)   = Just n
declarationName (EnumDecl n _ _)         = Just n
declarationName (EnumValueDecl n _ _)    = Just n
declarationName (StructDecl n _ _)       = Just n
declarationName (FieldDecl n _ _ _ _)    = Just n
declarationName (UnionDecl n _ _ _)      = Just n
declarationName (InterfaceDecl n _ _)    = Just n
declarationName (MethodDecl n _ _ _ _)   = Just n
declarationName (AnnotationDecl n _ _ _) = Just n

declImports :: Declaration -> [Located String]
declImports (AliasDecl _ name) = maybeToList (declNameImport name)
declImports (ConstantDecl _ t ann _) = typeImports t ++ concatMap annotationImports ann
declImports (EnumDecl _ ann decls) = concatMap annotationImports ann ++ concatMap declImports decls
declImports (EnumValueDecl _ _ ann) = concatMap annotationImports ann
declImports (StructDecl _ ann decls) = concatMap annotationImports ann ++
                                       concatMap declImports decls
declImports (FieldDecl _ _ t ann _) = typeImports t ++ concatMap annotationImports ann
declImports (UnionDecl _ _ ann decls) = concatMap annotationImports ann ++
                                        concatMap declImports decls
declImports (InterfaceDecl _ ann decls) = concatMap annotationImports ann ++
                                          concatMap declImports decls
declImports (MethodDecl _ _ params t ann) =
    concat [concatMap paramImports params, typeImports t, concatMap annotationImports ann]
declImports (AnnotationDecl _ t ann _) = typeImports t ++ concatMap annotationImports ann
